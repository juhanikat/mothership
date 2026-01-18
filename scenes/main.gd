extends Node2D
class_name Main


@export var camera: Camera2D

@export var nav_region: NavigationRegion2D

@export var nav_actor: Node2D
@export var nav_agent: NavigationAgent2D
@export var path_line: Line2D

# All rooms are children of this node
@export var room_nodes: Node2D
# All room info boxes are children of this node
@export var room_info_nodes: Control

@export var room_selection: RoomSelection

@onready var hud = get_node("HUD")

var room_scene = load("res://room/room.tscn")
var room_info_scene = load("res://room/room_info.tscn")

const room_data = RoomData.room_data

var path_start: Vector2
var path_start_room: Room # the room where the path starts
var path_end: Vector2
var path_end_room: Room # the room where the path ends

var camera_dragging: bool = false
var previous_mouse_pos_dragging: Vector2 = Vector2(0, 0)
var previous_mouse_pos_zooming: Vector2 = Vector2(0, 0)

var spawned_room_names = {} # used to give new rooms an ordering number (purely visual atm)

var turn: int = 1
var total_crew: int = 0
var crew_quarters_limit: int = 1



func _ready() -> void:
	var first_order = CaptainFunctions.get_starting_order()
	var possible_rooms: Array[Dictionary]
	possible_rooms.assign(first_order.selected_rooms)
	room_selection.show_order(first_order.description, possible_rooms)

	GlobalSignals.crew_added.connect(_on_crew_added)
	GlobalSignals.crew_removed.connect(_on_crew_removed)
	GlobalSignals.crew_quarters_limit_raised.connect(_on_crew_quarters_limit_raised)
	GlobalSignals.crew_quarters_limit_lowered.connect(_on_crew_quarters_limit_lowered)
	GlobalSignals.turn_advanced.connect(_on_next_turn)

	# starting room
	var first_room = spawn_room_at_mouse(room_data[RoomData.RoomType.POWER_PLANT])
	first_room.is_starting_room = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("path_build_mode"):
		GlobalInputFlags.path_build_mode = not GlobalInputFlags.path_build_mode

	if event.is_action_pressed("drag_camera"):
		camera_dragging = true
	if event.is_action_released("drag_camera"):
		camera_dragging = false
		previous_mouse_pos_dragging = Vector2(0, 0)

	if event.is_action_pressed("zoom_in") and camera.zoom < Vector2(3, 3):
		camera.zoom += Vector2(0.2, 0.2)
		camera.global_position += (get_global_mouse_position() - camera.global_position).normalized() * (75 / (camera.zoom.x * 3))
	if event.is_action_pressed("zoom_out") and camera.zoom > Vector2(0.5, 0.5):
		camera.zoom -= Vector2(0.2, 0.2)

	if event is InputEventMouseMotion and camera_dragging:
		camera.global_position += event.relative * (3 / (camera.zoom.x * 3)) # this is mouse movement direction from center of screen I think?

	if event.is_action_pressed("add_point_to_path") and GlobalInputFlags.path_build_mode:
		var mouse_pos = get_global_mouse_position()
		if not path_start:
			path_line.clear_points() # clear the line from previous navigation
			path_start = mouse_pos
			path_start_room = find_clicked_room()
		else:
			path_end = mouse_pos
			path_end_room = find_clicked_room()

			if path_start_room and path_end_room:
				find_path(path_start, path_end)
				var path_length = RoomConnections.distance_between(path_start_room, path_end_room)
				GlobalSignals.path_completed.emit(path_start_room, path_end_room, path_length)
			else:
				print("Path does not start and end inside a room or connector!")
			path_start = Vector2(0, 0)
			path_end = Vector2(0, 0)


func _physics_process(_delta: float) -> void:
	if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		return
	if nav_agent.is_navigation_finished() or not nav_agent.is_target_reachable():
		return

	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	path_line.add_point(nav_actor.global_position)
	path_line.add_point(next_path_position)
	nav_actor.global_position = next_path_position


func find_clicked_room() -> Variant:
	## Called from _unhandled_input to return the room that has been clicked when building a path,
	## or null the mouse is not over any room.
	for room: Room in get_tree().get_nodes_in_group("Room"):
		if room.hovering:
			return room
	for connector: Connector in get_tree().get_nodes_in_group("Connector"):
		if connector.hovering:
			return connector.get_parent_room()
	return null


## Spawns a room at the position of the mouse (with picked = true), and returns the Room.
func spawn_room_at_mouse(new_room_data: Dictionary) -> Room:
	for room: Room in get_tree().get_nodes_in_group("Room"):
		if room.is_picked == true:
			print("Cannot spawn new room at mouse pos when an existing one is picked!")
			return

	var new_room: Room = room_scene.instantiate()
	var new_room_shape = new_room_data["room_shape"]
	new_room.init_room(new_room_data, true)
	new_room.global_position = get_global_mouse_position()

	var room_name = new_room_data["room_name"]
	var overwrite_name = ""
	if not spawned_room_names.get(room_name):
		spawned_room_names[room_name] = 1
	else:
		spawned_room_names[room_name] += 1
	if spawned_room_names[room_name] > 1:
		overwrite_name = "%s (%s)" % [room_name, spawned_room_names[room_name]]

	room_nodes.add_child(new_room)

	# room info is a child of main scene because otherwise it will rotate with the room
	var new_room_info: RoomInfo = room_info_scene.instantiate()
	new_room_info.init_room_info(new_room_data, overwrite_name)
	new_room_info.global_position = new_room.global_position + RoomData.room_info_pos[new_room_shape]
	# room is responsible for moving info box with the room itself,
	# so it needs a reference of it
	new_room.room_info = new_room_info
	room_info_nodes.add_child(new_room_info)

	return new_room


func find_path(from: Vector2, to: Vector2) -> void:
	## Find path between two positions.
	nav_actor.global_position = from
	nav_agent.set_target_position(to)
	if not nav_agent.is_target_reachable():
		print("Position (%s) is not reachable from position (%s)!" % [str(to), str(from)])


## Gets a new order from the captain and shows the corresponding buttons in the HUD.
func _on_next_turn() -> void:
	turn += 1

	var next_order: Dictionary
	if turn == 3:
		next_order = CaptainFunctions.get_specific_order(CaptainData.Order.CARGO_BAY_ORDER)
	else:
		next_order = CaptainFunctions.get_random_order()

	var possible_rooms: Array[Dictionary]
	possible_rooms.assign(next_order.selected_rooms)
	room_selection.clear_room_buttons()
	room_selection.show_order(next_order.description, possible_rooms)


func cut_room_shape_from_nav_region(room: Room, connectors: Array[Connector]) -> void:
	var room_polygon = room.polygon.polygon
	var global_room_polygon = []
	var nav_obstacle
	for point in room_polygon:
		global_room_polygon.append(point + room.global_position)

	nav_obstacle = NavigationObstacle2D.new()
	nav_obstacle.vertices = global_room_polygon
	nav_obstacle.affect_navigation_mesh = true
	nav_region.add_child(nav_obstacle)

	for connector in connectors:
		var connector_polygon = connector.collision_polygon.polygon
		var global_connector_polygon = []
		for point in connector_polygon:
			global_connector_polygon.append(point + connector.global_position)

		nav_obstacle = NavigationObstacle2D.new()
		nav_obstacle.vertices = global_connector_polygon
		nav_obstacle.affect_navigation_mesh = true
		nav_region.add_child(nav_obstacle)

	if nav_region.is_baking():
		await nav_region.bake_finished
	nav_region.bake_navigation_polygon()


func new_cargo_order(cargo_bay: Room) -> void:
	hud.show_cargo_popup(cargo_bay)


func order_cargo(order_type: String, ordering_cargo_bay: Room) -> bool:
		var delivery = {"type": order_type, "turns_left": 3, "made_by": ordering_cargo_bay}
		GlobalSignals.cargo_bay_order_made.emit(delivery)
		return true


func _on_crew_added(amount: int) -> void:
	total_crew += amount


func _on_crew_removed(amount: int) -> void:
	total_crew -= amount


func _on_crew_quarters_limit_raised(amount: int) -> void:
	crew_quarters_limit += amount


func _on_crew_quarters_limit_lowered(amount: int) -> void:
	crew_quarters_limit -= amount
