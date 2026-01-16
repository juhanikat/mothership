extends Area2D
class_name Room

var connector_scene = load("res://room/connector.tscn")

const RoomShape = RoomData.RoomShape

@export var texture_polygon: Polygon2D
@export var nav_region: NavigationRegion2D
@export var nav_agent: NavigationAgent2D
@export var connectors_node: Node2D
@export var polygon: CollisionPolygon2D # actual CollisionPolygon of the room
@export var all_room_shapes: Area2D # all possible room types are children of this node

@export var raycast: RayCast2D # if room data has a facing property, this raycast will be cast toward that side.
# used to check if any other rooms are in front of this room, if needed.

@onready var room_shapes: Dictionary[RoomShape, PackedVector2Array]
@onready var main: Main = get_tree().root.get_node("Main")

var room_info: RoomInfo # The room's info box, this is a child of the main node

const MAX_CONNECTOR_DISTANCE = 40

var hovering: bool = false # true when mouse is hovering over this room.
var is_picked: bool = false # true when the room is picked by mouse.
var locked: bool = false # true once room has been placed and can no longer be moved.
var connecting_rooms: bool = false # used in _unhandled_input to keep room still while connecting.
var target_rotation: float = 0

var _shape: RoomData.RoomShape
var _data: Dictionary[String, Variant]
var room_name: String
var room_type: RoomData.RoomType
var room_category: RoomData.RoomCategory

var overlapping_rooms: Array[Room] = []
var adjacent_rooms: Array[Room] = [] # updated when any room is attached to this one

var gameplay: RoomGameplay
var is_starting_room: bool = false # the first room in the game is the only one that can be palced while not connected.



## Call this before the room is added to the scene tree.
func init_room(i_data: Dictionary[String, Variant], picked: bool = false) -> void:
	_data = i_data
	_shape = _data["room_shape"]
	room_name = _data["room_name"]
	room_type = RoomData.room_data.find_key(_data)
	room_category = _data["room_category"]
	is_picked = picked

	# creates connectors for the room, depending on its shape
	create_connectors()


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

	polygon.polygon = room_shapes[_shape]

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
		match _data.facing:
			"up":
				raycast.target_position = Vector2(0, -50000)
			"right":
				raycast.target_position = Vector2(50000, 0)
			"down":
				raycast.target_position = Vector2(0, 50000)
			"left":
				raycast.target_position = Vector2(-50000, 0)
	else:
		raycast.enabled = false



	GlobalSignals.room_connected.connect(_on_room_connected)

	# RoomGameplay handles supplying power etc. gameplay things
	gameplay = RoomGameplay.new()
	add_child(gameplay)
	gameplay.init_gameplay_features(_data)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("activate_room") and hovering and not is_picked:
		if gameplay.activated:
			gameplay.deactivate_room()
		else:
			gameplay.activate_room()
		return

	if locked:
		return

	if GlobalInputFlags.path_build_mode:
		return

	if event.is_action_pressed("cancel_room") and is_picked and not is_starting_room:
		room_info.queue_free()
		main.spawned_room_names[room_name] -= 1
		queue_free()
		return

	await get_tree().physics_frame # to make sure area overlap is detected

	if event.is_action_pressed("move_room") and event.is_pressed():
		if is_picked:
			connecting_rooms = true
			var all_connectors: Array[Connector]
			# weird trick to cast the type correctly
			all_connectors.assign(get_tree().get_nodes_in_group("Connector"))
			var connector_pair: Array[Connector] = RoomConnections.find_connector_pairing(get_own_connectors(), all_connectors, 20)
			if len(connector_pair) == 2:
				var connected = await connect_rooms(connector_pair)
				if connected:
					is_picked = false
					locked = true
				connecting_rooms = false
				return
			connecting_rooms = false
			if is_starting_room:
				is_picked = false

	if event is InputEventMouseMotion and is_picked and not connecting_rooms:
		var global_mouse_pos = get_global_mouse_position()
		global_position = global_mouse_pos
		room_info.global_position = global_position + RoomData.room_info_pos[_shape]

	if event.is_action_pressed("rotate_tile") and is_picked:
			target_rotation += 90


func _process(_delta: float) -> void:
	rotation_degrees = lerpf(rotation_degrees, target_rotation, 0.15)

	#snap rotation to target value once close enough, might prevent some bugs with rounding
	if abs(rotation_degrees - target_rotation) < 0.05:
		rotation_degrees = target_rotation


## Called when a room is placed while near another room.
## If the room can be placed, the "room_connected" signal is emitted and the list of own connectors
## is looped through so that ALL newly adjacent rooms can get connected properly.
func connect_rooms(connector_pair: Array[Connector]) -> bool:
	var rules_passed = RoomConnections.check_placement_rules(self, connector_pair[1].get_parent_room())
	if not rules_passed:
		return false

	## Actual connection code
	var original_position = global_position
	var to = connector_pair[1].global_position - connector_pair[0].global_position
	global_position += to
	room_info.global_position += to

	# check for overlapping rooms AFTER placing connected room
	await get_tree().physics_frame
	if len(overlapping_rooms) > 0:
		if RoomConnections.is_replacing_placeholder_room(self, overlapping_rooms):
			# replaces a placeholder room, all things that are normally done when the room_connected signal is emitted
			# must be done here
			overlapping_rooms[0].replace_placeholder(self)
			GlobalNotice.display("Replaced a placeholder room.")
			if gameplay.always_activated:
				gameplay.activate_room()
				GlobalNotice.display("Room activated automatically!")
			return true
		else:
			global_position = original_position
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

	print("Connectors ({0}) and ({1}) snapped together.".format([str(connector_pair[0]), str(connector_pair[1])]))
	GlobalSignals.room_connected.emit(connector_pair[0], connector_pair[1])

	await get_tree().physics_frame
	for connector in get_own_connectors():
		var connected_to: Connector = connector.connected_to()
		if connected_to and connected_to.get_parent_room() not in adjacent_rooms:
			GlobalSignals.room_connected.emit(connector, connected_to)
	return true


func create_connectors() -> void:
	for connector_pos in RoomData.room_connectors[_shape]:
		var new_connector: Area2D = connector_scene.instantiate()
		connectors_node.add_child(new_connector)
		new_connector.position = connector_pos


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
	elif connector2 in get_own_connectors():
		locked = true
		var other_room = connector1.get_parent_room()
		adjacent_rooms.append(other_room)
		room_info.update_adjacent_rooms_label(adjacent_rooms)
		connector2.delete_navigation_region()
		main.cut_room_shape_from_nav_region(self, get_own_connectors())

		## TODO: ??? Is this necessary, or in the right place?
		await get_tree().physics_frame
		for connector in connector2.get_overlapping_connectors():
			if connector == connector1:
				continue
			print("Deleted connector %s" % [str(connector)])
			connector.queue_free()


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


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Room"):
		overlapping_rooms.append(area)


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("Room"):
		overlapping_rooms.erase(area)


func _on_mouse_entered() -> void:
	hovering = true
	## NOTE: room_info's description label is toggled here since room_info itself
	## cannot be easily set to read input without consuming it :(
	room_info.description_label.show()
	room_info.adjacent_rooms_label.show()
	room_info.z_index = 1


func _on_mouse_exited() -> void:
	hovering = false
	room_info.description_label.hide()
	room_info.adjacent_rooms_label.hide()
	room_info.shrink_panel_container()
	room_info.z_index = 0
