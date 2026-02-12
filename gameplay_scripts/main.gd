class_name Main
extends Node2D

const RoomType = RoomData.RoomType
const room_data = RoomData.room_data

@export var room_selection: RoomSelection
@export var hud: Hud

@export var camera: Camera2D
@export var nav_region: NavigationRegion2D
@export var nav_actor: Node2D
@export var nav_agent: NavigationAgent2D
@export var path_line: Line2D

# All rooms are children of this node
@export var room_nodes: Node2D
# All room info boxes are children of this node
@export var room_info_nodes: Control

@export var testing_room_nodes: Node2D # holds rooms that are spawned when the game starts, for testing
@export var testing_room_locations: Node2D # holds locations for above rooms

var room_scene = load("res://scenes/room.tscn")
var event_functions_scene = load("res://gameplay_scripts/EventFunctions.gd")

# used for the path (press Space)
var path_start: Vector2
var path_start_room: Room # the room where the path starts
var path_end: Vector2
var path_end_room: Room # the room where the path ends

var camera_dragging: bool = false
const default_zoom: Vector2 = Vector2(1.5, 1.5)
var previous_mouse_pos_dragging: Vector2 = Vector2(0, 0)
var previous_mouse_pos_zooming: Vector2 = Vector2(0, 0)

var total_crew: int = 0
var crew_quarters_limit: int = 3
var spawned_room_names = { } # used to give new rooms an ordering number (purely visual atm)
var used_crew_names: Array[String] = [] # to make sure no crew member name is used twice, should improve this later

## NOTE: Change these when testing!
var create_testing_rooms: bool = true
var NO_CARGO_BAY_REQUIREMENT: bool = true



## Creates a new room at <pos>, and adds it as a child to TestingRoom.
func create_testing_room(room_type: RoomData.RoomType, pos: Vector2) -> Room:
	var new_room = room_scene.instantiate()
	new_room.init_room(RoomData.room_data[room_type])
	new_room.global_position = pos
	testing_room_nodes.add_child(new_room)
	return new_room


func _ready() -> void:
	camera.zoom = default_zoom
	var first_order = OrderFunctions.get_starting_order()
	var possible_rooms: Array[Dictionary]
	possible_rooms.assign(first_order.selected_rooms)
	room_selection.show_order(first_order.description, possible_rooms)

	GlobalSignals.crew_quarters_limit_raised.connect(_on_crew_quarters_limit_raised)
	GlobalSignals.crew_quarters_limit_lowered.connect(_on_crew_quarters_limit_lowered)
	GlobalSignals.turn_advanced.connect(_on_next_turn)

	if create_testing_rooms:
		var testing_room_types = [RoomType.CREW_QUARTERS, RoomType.CANTEEN, RoomType.FUEL_STORAGE, RoomType.POWER_PLANT]
		for location: Node2D in testing_room_locations.get_children():

			# creates testing room and adds it as a child to TestingRooms.
			# it's best to keep TestingROomLocations in a straight line so the rooms can connect easily
			# also, make sure the amount of spawned rooms matches the amount of locations!
			var new_room = create_testing_room(testing_room_types.pop_front(), location.global_position)
			# connects all rooms that are placed by default, as long as they are near enough one another
			var all_connectors: Array[Connector]
			all_connectors.assign(get_tree().get_nodes_in_group("Connector"))
			var connector_pair: Array[Connector] = RoomConnections.find_connector_pairing(new_room.get_own_connectors(), all_connectors, 1000)
			if len(connector_pair) > 0 and not new_room.locked:
				await new_room.connect_rooms(connector_pair)

			await get_tree().physics_frame
			for room: Room in get_tree().get_nodes_in_group("Room"):
				assert(len(room.overlapping_rooms) == 0, "Testing rooms did not connect properly, move the locations around a bit.")

			if len(testing_room_types) == 0:
				break


func _physics_process(_delta: float) -> void:
	if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		return
	if nav_agent.is_navigation_finished() or not nav_agent.is_target_reachable():
		return

	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	path_line.add_point(nav_actor.global_position)
	path_line.add_point(next_path_position)
	nav_actor.global_position = next_path_position


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
		if room.picked == true:
			print("Cannot spawn new room at mouse pos when an existing one is picked!")
			return

	var new_room: Room = room_scene.instantiate()
	new_room.init_room(new_room_data, true)
	new_room.global_position = get_global_mouse_position()

	if len(get_tree().get_nodes_in_group("Room")) == 0:
		# this room is the first room
		new_room.is_starting_room = true
	# everything else, like creating room_info, is done inside the room's _ready() function
	room_nodes.add_child(new_room)
	return new_room


func find_path(from: Vector2, to: Vector2) -> void:
	## Find path between two positions.
	nav_actor.global_position = from
	nav_agent.set_target_position(to)
	if not nav_agent.is_target_reachable():
		print("Position (%s) is not reachable from position (%s)!" % [str(to), str(from)])


## Returns true if the player has done all that is needed to do on the current turn
## (for example, the three starting rooms have to be placed on the first turn to continue).
func check_turn_requirements() -> bool:
	if GlobalVariables.turn == 1:
		var all_room_types = get_tree().get_nodes_in_group("Room").map(func(room: Room): return room.room_type)
		for required_type in [RoomData.RoomType.COMMAND_ROOM, RoomData.RoomType.FUEL_STORAGE, RoomData.RoomType.POWER_PLANT]:
			if required_type not in all_room_types:
				GlobalNotice.display("Place all required rooms first.", "warning")
				return false
	elif GlobalVariables.turn == 3 and not NO_CARGO_BAY_REQUIREMENT:
		var cargo_bay = get_tree().get_nodes_in_group(str(RoomType.CARGO_BAY))
		if not cargo_bay:
			GlobalNotice.display("Place all required rooms first.", "warning")
			return false
	return true


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
	var delivery = { "type": order_type, "turns_left": 3, "made_by": ordering_cargo_bay }
	GlobalSignals.cargo_bay_order_made.emit(delivery)
	return true


## Gets a new order from the captain and shows the corresponding buttons in the HUD.
## Also calls next_turn() inside each RoomGameplay.
func _on_next_turn() -> void:
	if hud.event_popup.visible:
		hud.event_popup.hide()
	GlobalVariables.turn += 1
	for gameplay: RoomGameplay in get_tree().get_nodes_in_group("RoomGameplay"):
		gameplay.next_turn()

	var next_order: Dictionary
	if GlobalVariables.turn == 3:
		next_order = OrderFunctions.get_specific_order(OrderData.Order.CARGO_BAY_ORDER)
	else:
		var active_data_analysis_rooms = get_tree().get_nodes_in_group(str(RoomType.DATA_ANALYSIS)).filter(func(room: Room): return room.gameplay.activated)
		next_order = OrderFunctions.get_random_order(len(active_data_analysis_rooms))

	var possible_rooms: Array[Dictionary]
	possible_rooms.assign(next_order.selected_rooms)
	room_selection.clear_room_buttons()
	room_selection.show_order(next_order.description, possible_rooms)

	EventFunctions.print_event_info(get_tree())
	var next_event_data = EventFunctions.get_random_event(get_tree())
	if next_event_data:
		hud.event_popup.show_event(next_event_data)


func _on_crew_added(amount: int) -> void:
	total_crew += amount


func _on_crew_removed(amount: int) -> void:
	total_crew -= amount


func _on_crew_quarters_limit_raised(amount: int) -> void:
	crew_quarters_limit += amount


func _on_crew_quarters_limit_lowered(amount: int) -> void:
	crew_quarters_limit -= amount
