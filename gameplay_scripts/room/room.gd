class_name Room
extends Area2D

const RoomShape = RoomData.RoomShape
const MAX_CONNECTOR_DISTANCE = 40

@export var check_connection_timer: Timer
@export var texture_polygon: Polygon2D
@export var crew_member_node: Node2D
@export var highlight_line: Line2D
@export var highlight_line_timer: Timer
@export var highlight_anim_player: AnimationPlayer
@export var nav_region: NavigationRegion2D
@export var nav_agent: NavigationAgent2D
@export var connectors_node: Node2D
@export var polygon: CollisionPolygon2D # actual CollisionPolygon of the room
@export var all_room_shapes: Area2D # all possible room types are children of this node
@export var all_room_highlights: Node2D # all highlights corresponding to above room types are children of this node
@export var raycast: RayCast2D # if room data has a facing property, this raycast will be cast toward that side.
# used to check if any other rooms are in front of this room, if needed.
@export var raycast_line: Line2D

var connector_scene = load("res://scenes/connector.tscn")
var room_info_scene = load("res://scenes/room_info.tscn")

var room_info: RoomInfo # The room's info box, this is a child of the main node
var hovering: bool = false # true when mouse is hovering over this room.
var picked: bool = false # true when the room is picked by mouse.
var locked: bool = false # true once room has been placed and can no longer be moved.
var rotating: bool = false # true if the room is currently rotating.

var connecting_rooms: bool = false # used in _unhandled_input to keep room still while connecting.
var closest_conns_pair = [] # used to highlight two Connectors that are close enough to pair


var room_name: String
var room_type: RoomData.RoomType
var room_category: RoomData.RoomCategory
var overlapping_rooms: Array[Room] = []
var adjacent_rooms: Array[Room] = [] # updated when any room is attached to this one
var gameplay: RoomGameplay

var is_starting_room: bool = false # the first room in the game is the only one that can be placed while not connected.
var _shape: RoomData.RoomShape
var _data: Dictionary[String, Variant]

@onready var room_shapes: Dictionary[RoomShape, PackedVector2Array]
@onready var room_highlight_lines: Dictionary[RoomShape, PackedVector2Array]
@onready var main: Main = get_tree().root.get_node("Main")


## NOTE: Also creates the room_info node and adds it to the main scene.
func _ready() -> void:
	assert(len(_data.keys()) > 0)

	for room_shape in all_room_shapes.get_children():
		if room_shape.name == "LShapePolygon":
			room_shapes[RoomShape.LShape] = room_shape.polygon
		if room_shape.name == "TShapePolygon":
			room_shapes[RoomShape.TShape] = room_shape.polygon
		if room_shape.name == "SquareShapePolygon":
			room_shapes[RoomShape.SmallSquareShape] = room_shape.polygon
		if room_shape.name == "BigSquareShapePolygon":
			room_shapes[RoomShape.BigSquareShape] = room_shape.polygon
		if room_shape.name == "LongHallwayShapePolygon":
			room_shapes[RoomShape.LongHallwayShape] = room_shape.polygon
		if room_shape.name == "MediumHallwayShapePolygon":
			room_shapes[RoomShape.MediumHallwayShape] = room_shape.polygon

	for room_highlight_line: Line2D in all_room_highlights.get_children():
		if room_highlight_line.name == "LShapeLine":
			room_highlight_lines[RoomShape.LShape] = room_highlight_line.points
		if room_highlight_line.name == "TShapeLine":
			room_highlight_lines[RoomShape.TShape] = room_highlight_line.points
		if room_highlight_line.name == "SquareShapeLine":
			room_highlight_lines[RoomShape.SmallSquareShape] = room_highlight_line.points
		if room_highlight_line.name == "BigSquareShapeLine":
			room_highlight_lines[RoomShape.BigSquareShape] = room_highlight_line.points
		if room_highlight_line.name == "LongHallwayShapeLine":
			room_highlight_lines[RoomShape.LongHallwayShape] = room_highlight_line.points
		if room_highlight_line.name == "MediumHallwayShapeLine":
			room_highlight_lines[RoomShape.MediumHallwayShape] = room_highlight_line.points

	polygon.polygon = room_shapes[_shape]

	if room_highlight_lines.get(_shape):
		highlight_line.points = room_highlight_lines[_shape]

	# creates connectors for the room, depending on its shape
	if "delete_conns" in _data:
		var delete_conns_list: Array[String] = []
		delete_conns_list.assign(_data["delete_conns"])
		create_connectors(delete_conns_list)
	else:
		create_connectors([])

	# shapes the texture (Polygon2D) according to the room's shape,
	# and colors it according to its category.
	# Replace this when creating actual textures for rooms.
	create_texture()

	# creates and shapes the NavigationRegion for the room.
	create_navigation_region()

	raycast.add_exception(self)
	for own_connector in get_own_connectors():
		raycast.add_exception(own_connector)
	if "facing" in _data:
		raycast.show()
		raycast_line.show()
		match _data.facing:
			"up":
				raycast.target_position = Vector2(0, -50000)
				raycast_line.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -50000)])
			"right":
				raycast.target_position = Vector2(50000, 0)
				raycast_line.points = PackedVector2Array([Vector2(0, 0), Vector2(50000, 0)])
			"down":
				raycast.target_position = Vector2(0, 50000)
				raycast_line.points = PackedVector2Array([Vector2(0, 0), Vector2(0, 50000)])
			"left":
				raycast.target_position = Vector2(-50000, 0)
				raycast_line.points = PackedVector2Array([Vector2(0, 0), Vector2(-50000, 0)])
	else:
		raycast.enabled = false

	GlobalSignals.room_connected.connect(_on_room_connected)

	# RoomGameplay handles supplying power etc. gameplay things
	gameplay = RoomGameplay.new()
	add_child(gameplay)
	gameplay.init_gameplay_features(_data)

	var overwrite_name = ""
	if not main.spawned_room_names.get(room_name):
		main.spawned_room_names[room_name] = 1
	else:
		main.spawned_room_names[room_name] += 1
	if main.spawned_room_names[room_name] > 1:
		overwrite_name = "%s (%s)" % [room_name, main.spawned_room_names[room_name]]

	var new_room_info: RoomInfo = room_info_scene.instantiate()
	new_room_info.init_room_info(self, _data, overwrite_name)
	new_room_info.global_position = global_position + RoomData.room_info_pos[_shape]
	room_info = new_room_info
	main.room_info_nodes.add_child(new_room_info)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("activate_room") and hovering and not GlobalVariables.room_is_picked:
		if gameplay.activated:
			gameplay.deactivate_room()
		else:
			gameplay.activate_room()
		return

	if GlobalInputFlags.path_build_mode:
		return

	if locked:
		if event.is_action_pressed("move_crew") and hovering:
			# checks if a crew member is already picked
			var picked_crew = get_tree().get_nodes_in_group("CrewMember").filter(func(crew: CrewMember): return crew.picked)
			if len(picked_crew) > 0:
				# there should be only one CrewMember in the picked_crew Array
				assert(len(picked_crew) == 1)
				picked_crew[0].picked = false
				picked_crew[0].hide()
				GlobalVariables.picked_crew = null
				var crew_assigned = gameplay.assign_crew(picked_crew[0])
				if crew_assigned:
					GlobalNotice.display("Moved crew member to another room.")
			else:
				var assigned_crew = get_tree().get_nodes_in_group("CrewMember").filter(func(crew: CrewMember): return crew.assigned_to == self)
				if len(assigned_crew) > 0:
					assigned_crew[0].picked = true
					assigned_crew[0].show()
					GlobalVariables.picked_crew = assigned_crew[0]
		return

	if picked:
		if event.is_action_pressed("cancel_room"):
			room_info.queue_free()
			main.spawned_room_names[room_name] -= 1
			GlobalVariables.room_is_picked = false
			queue_free()
			return

		if event.is_action_pressed("move_room") and not connecting_rooms and not rotating:
			connecting_rooms = true
			var conn_pair = get_connection_candidates()
			if conn_pair:
				var connected = await try_to_connect_rooms(conn_pair)
				if connected:
					picked = false
					GlobalVariables.room_is_picked = false
					room_info.shrink_info()
					locked = true
				connecting_rooms = false
				return
			connecting_rooms = false

			if is_starting_room:
				picked = false
				GlobalVariables.room_is_picked = false
				locked = true
				room_info.shrink_info()

		if event is InputEventMouseMotion and not connecting_rooms:
			var global_mouse_pos = get_global_mouse_position()
			global_position = global_mouse_pos
			room_info.global_position = global_position + RoomData.room_info_pos[_shape] # + room_info.relative_pos

		if event.is_action_pressed("rotate_tile") and not rotating:
			rotating = true
			var rotation_tween = get_tree().create_tween()
			rotation_tween.tween_property(self, "rotation_degrees", rotation_degrees + 90, 0.3).set_trans(Tween.TRANS_BACK)
			# waits for rotation before doing anything else, otherwise connecting rooms while the room is rotating might crash the game
			await rotation_tween.finished
			rotating = false


## Call this before the room is added to the scene tree.
func init_room(i_data: Dictionary[String, Variant], is_picked: bool = false) -> void:
	_data = i_data
	_shape = _data["room_shape"]
	room_name = _data["room_name"]
	room_type = RoomData.room_data.find_key(_data)
	room_category = _data["room_category"]
	picked = is_picked
	if is_picked:
		GlobalVariables.room_is_picked = true


func highlight(time: float = 2.0) -> void:
	highlight_anim_player.play("show_highlight")
	highlight_line_timer.start(time)


## Returns the Connector of this room that is closest to another room's Connector,
## or null if none are found in connection range.
func get_connection_candidates() -> Array:
	var closest_pair = []
	var closest_conn_distance = null

	var own_conns = get_own_connectors()
	for own_conn in own_conns:
		for other_conn: Connector in get_tree().get_nodes_in_group("Connector"):
			if other_conn in own_conns:
				continue
			var distance = own_conn.global_position.distance_to(other_conn.global_position)
			if distance < 75 and (len(closest_pair) == 0 or distance < closest_conn_distance):
				closest_pair = [own_conn, other_conn]
				closest_conn_distance = distance
	return closest_pair


## Called when a room is placed while near another room.
## If the room can be placed, the "room_connected" signal is emitted and the list of own connectors
## is looped through so that ALL newly adjacent rooms can get connected properly.
func try_to_connect_rooms(connector_pair, no_animation: bool = false) -> bool:
	print("here")
	var rules_passed = RoomConnections.check_placement_rules(self, connector_pair[1].get_parent_room())
	if not rules_passed:
		return false

	## Actual movement code
	var to = connector_pair[1].global_position - connector_pair[0].global_position
	if no_animation:
		global_position += to
		room_info.global_position += to
	else:
		var room_movement_tween = get_tree().create_tween()
		var room_info_movement_tween = get_tree().create_tween()
		room_movement_tween.tween_property(self, "global_position", global_position + to, 0.2)
		room_info_movement_tween.tween_property(room_info, "global_position", room_info.global_position + to, 0.2)
		# waits for room to reposition before checking overlaps etc.
		await room_movement_tween.finished

	await get_tree().physics_frame
	if len(overlapping_rooms) > 0:
		if RoomConnections.is_replacing_placeholder_room(self, overlapping_rooms):
			for adjacent_room in overlapping_rooms[0].adjacent_rooms:
				rules_passed = RoomConnections.check_placement_rules(self, adjacent_room)
				if not rules_passed:
					return false
			# replaces a placeholder room, all things that are normally done when the room_connected signal is emitted
			# must be done here
			overlapping_rooms[0].replace_placeholder(self)
			GlobalNotice.display("Replaced a placeholder room.")
			if gameplay.always_activated:
				gameplay.activate_room()
				GlobalNotice.display("Room activated automatically!")
			return true
		else:
			GlobalNotice.display("Tried to snap connectors, but rooms are overlapping.", "warning")
			return false

	await get_tree().physics_frame
	var collider = get_raycast_collider()
	if collider:
		GlobalNotice.display("Cannot place room, another room or connector is overlapping the raycast.", "warning")
		return false

	for other_room: Room in get_tree().get_nodes_in_group("Room"):
		var other_room_collider = other_room.get_raycast_collider()
		if other_room_collider:
			GlobalNotice.display("Cannot place room, this room is overlapping another room's raycast.", "warning")
			return false

	GlobalSignals.room_connected.emit(connector_pair[0], connector_pair[1])

	await get_tree().physics_frame
	for connector in get_own_connectors():
		var connected_to: Connector = connector.connected_to()
		if connected_to and connected_to.get_parent_room() not in adjacent_rooms:
			GlobalSignals.room_connected.emit(connector, connected_to)
	return true

## <deleted_connectors> is a list of conn directions which are not added to this room,
## e.g. ["up", "down"].
func create_connectors(deleted_connectors: Array[String]) -> void:
	for i in range(len(RoomData.room_connectors[_shape])):
		var conn_pos = RoomData.room_connectors[_shape][i]
		var conn_direction = RoomData.room_conn_directions[_shape][i]
		if conn_direction in deleted_connectors:
			continue
		var new_connector: Area2D = connector_scene.instantiate()
		connectors_node.add_child(new_connector)
		new_connector.position = conn_pos


## Creates a navigation region for this room (connector regions are made in connector.gd).
func create_navigation_region() -> void:
	var new_nav_polygon = NavigationPolygon.new()
	new_nav_polygon.agent_radius = 0 # otherwise the shape will be too small to exist!
	new_nav_polygon.add_outline(room_shapes[_shape])
	nav_region.navigation_polygon = new_nav_polygon
	nav_region.bake_navigation_polygon()


func create_texture() -> void:
	texture_polygon.polygon = polygon.polygon
	texture_polygon.color = RoomData.room_colors[room_category]
	texture_polygon.color.a -= 0.5 # because rooms spawn unpowered


## Returns all connectors that are children of this room.
func get_own_connectors() -> Array[Connector]:
	var all_connectors = get_tree().get_nodes_in_group("Connector")
	var own_connectors: Array[Connector] = []
	for connector in all_connectors:
		# check if connector is a child of this room, and add it to own_connectors
		if connectors_node.is_ancestor_of(connector):
			own_connectors.append(connector)
	return own_connectors


## Returns the first room or connector that hits this room's raycast, if any.
## NOTE: this will have issues if new children are added to Room, since subchildren of this room
## (other than connectors) are not excluded from the collider check.
func get_raycast_collider():
	if not raycast.enabled:
		return null

	var collider = raycast.get_collider()
	if collider is not Room and collider is not Connector:
		return null

	return collider


## NOTE: Only call this if the room is a Placeholder room.
## Replaces this room with <replacer>, giving it this room's adjacent_rooms list.
## Also updates the adjacent_rooms lists of every adjacent room.
## The replacer room should already be at the same coordinates as this room before calling this function.
func replace_placeholder(replacer: Room) -> void:
	replacer.adjacent_rooms = adjacent_rooms
	replacer.room_info.update_adjacent_rooms_label(replacer.adjacent_rooms)
	for room: Room in replacer.adjacent_rooms:
		room.adjacent_rooms.append(replacer)
		room.adjacent_rooms.erase(self)
		room.room_info.update_adjacent_rooms_label(room.adjacent_rooms)

	room_info.queue_free()
	main.spawned_room_names[room_name] -= 1
	queue_free()


## If one of the connectors belongs to this room, lock the room, and add the owner of the
## other connector to this rooms adjacent_rooms list.
## If the connector belonging to this room is connector2, also delete
## the connectors NavigationRegion (this has to be done in one of the connectors).
func _on_room_connected(connector1: Connector, connector2: Connector) -> void:
	if connector1 in get_own_connectors():
		locked = true
		var other_room = connector2.get_parent_room()
		adjacent_rooms.append(other_room)
		room_info.update_adjacent_rooms_label(adjacent_rooms)
		main.cut_room_shape_from_nav_region(self, get_own_connectors())
		# connector nav regions are disabled until connected
		connector1.create_navigation_polygon()
	elif connector2 in get_own_connectors():
		locked = true
		var other_room = connector1.get_parent_room()
		adjacent_rooms.append(other_room)
		room_info.update_adjacent_rooms_label(adjacent_rooms)
		connector2.delete_navigation_region()
		main.cut_room_shape_from_nav_region(self, get_own_connectors())

	# done by all rooms in the game whenever any room is connected
	room_info.shrink_info()
	for conn in get_own_connectors():
		conn.check_deletion()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Room"):
		overlapping_rooms.append(area)


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("Room"):
		overlapping_rooms.erase(area)


func _on_mouse_entered() -> void:
	hovering = true
	if not picked:
		room_info.expand_info()


func _on_mouse_exited() -> void:
	hovering = false
	if not picked:
		room_info.shrink_info()


func _on_highlight_line_timer_timeout() -> void:
	highlight_anim_player.play("hide_highlight")


func _on_check_connection_timer_timeout() -> void:
	var new_conn_pair = get_connection_candidates()

	if new_conn_pair:
		if closest_conns_pair:
			closest_conns_pair[0].texture_polygon.color = closest_conns_pair[0].connector_color
			if closest_conns_pair[1]: # check because the connector might have been deleted
				closest_conns_pair[1].texture_polygon.color = closest_conns_pair[1].connector_color
		closest_conns_pair = new_conn_pair
		if not RoomConnections.check_placement_rules(
			new_conn_pair[0].get_parent_room(),
		 	new_conn_pair[1].get_parent_room(),
			false):
			closest_conns_pair[0].texture_polygon.color = Color(0.945, 0.376, 0.267, 1.0)
			closest_conns_pair[1].texture_polygon.color = Color(0.945, 0.376, 0.267, 1.0)
		else:
			closest_conns_pair[0].texture_polygon.color = Color(0.0, 0.886, 0.516)
			closest_conns_pair[1].texture_polygon.color = Color(0.0, 0.886, 0.516)
	elif closest_conns_pair:
		closest_conns_pair[0].texture_polygon.color = closest_conns_pair[0].connector_color
		closest_conns_pair[1].texture_polygon.color = closest_conns_pair[1].connector_color
		closest_conns_pair = []
	if locked:
		check_connection_timer.stop()
