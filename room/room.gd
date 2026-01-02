extends Node2D
class_name Room

var connector_scene = load("res://room/connector.tscn")

@export var texture_polygon: Polygon2D

@export var nav_region: NavigationRegion2D
@export var nav_agent: NavigationAgent2D
@export var connectors_node: Node2D

@export var room_area: Area2D # actual CollisionPolygon of the room
@export var polygon: CollisionPolygon2D # actual CollisionPolygon of the room
@export var all_room_shapes: Area2D # all possible room types are children of this node
@onready var room_shapes: Dictionary[RoomData.RoomShape, PackedVector2Array]

var room_info: RoomInfo # The room's info box, this is a child of the main node

const RoomShape = RoomData.RoomShape

const MAX_CONNECTOR_DISTANCE = 40

var hovering: bool = false # true when mouse is hovering over this room
var is_picked: bool = false
var locked: bool = false # true once room has been placed and can no longer be moved

var overlapping_room_areas: Array[Area2D] = []

var target_rotation: float = 0

var _shape: RoomData.RoomShape
var _data: Dictionary[String, Variant]

var adjacent_rooms: Array[Room] = [] # updated when any room is attached to this one


func init_room(i_data: Dictionary[String, Variant]) -> void:
	## Call this before the tile is added to the scene tree.
	_data = i_data
	_shape = _data["room_shape"]

	# creates connectors for the room, depending on it's shape
	create_connectors()


func _ready() -> void:
	assert(len(_data.keys()) > 0)

	for room_shape in all_room_shapes.get_children():
		if room_shape.name == "LShapePolygon":
			room_shapes[RoomShape.LShape] = room_shape.polygon
		if room_shape.name == "SquareShapePolygon":
			room_shapes[RoomShape.SmallSquareShape] = room_shape.polygon
		if room_shape.name == "BigSquareShapePolygon":
			room_shapes[RoomShape.BigSquareShape] = room_shape.polygon

	polygon.polygon = room_shapes[_shape]

	# shapes the texture (Polygon2D) according to the room's shape,
	# and colors it randomly.
	# Replace this when creating actual textures for rooms.
	create_texture()

	# creates and shapes the NavigationRegion for the room.
	create_navigation_region()

	GlobalSignals.room_connected.connect(_on_room_connected)


func _input(event: InputEvent) -> void:
	await get_tree().physics_frame # to make sure area overlap is detected
	await get_tree().physics_frame
	await get_tree().physics_frame

	if locked:
		return

	if GlobalInputFlags.path_build_mode:
		return

	if event is InputEventMouseButton and hovering and event.is_pressed():
		if is_picked:
			var connected = await connect_rooms()
			if connected:
				return

			if len(overlapping_room_areas) > 0:
				print("Cannot place room on top of another room.")
				return
			for connector in get_own_connectors():
				if len(connector.get_overlapping_room_areas()) > 0 or len(connector.get_overlapping_connectors()) > 0:
					print("Cannot place room while its connectors are overlapping another room or connector.")
					return
			is_picked = false

		elif len(overlapping_room_areas) == 0:
			is_picked = true
			var global_mouse_pos = get_global_mouse_position()
			global_position = global_mouse_pos
			room_info.global_position = global_position + RoomData.room_info_pos[_shape]
		return

	if event is InputEventMouseMotion and is_picked:
		var global_mouse_pos = get_global_mouse_position()
		global_position = global_mouse_pos
		room_info.global_position = global_position + RoomData.room_info_pos[_shape]

	elif event.is_action_pressed("rotate_tile") and is_picked:
			target_rotation += 90


func _process(_delta: float) -> void:
	if hovering:
		## NOTE: room_info's description label is toggled here since room_info itself
		## cannot be easily set to read input without consuming it :(
		if GlobalInputFlags.show_tooltips == true:
			room_info.description_popup_label.show()
		room_info.adjacent_rooms_popup_label.show()
	else:
		room_info.description_popup_label.hide()
		room_info.adjacent_rooms_popup_label.hide()

	rotation_degrees = lerpf(rotation_degrees, target_rotation, 0.15)

	#room_info.rotation_degrees =
	#snap rotation to target value once close enough, might prevent some bugs with rounding
	if abs(rotation_degrees - target_rotation) < 0.05:
		rotation_degrees = target_rotation


func connect_rooms() -> bool:
	## Called when a room is placed while it overlaps another room.
	## Locks the room in place while checking if it can be placed, then either
	## places it or removes the lock.
	## If the room is placed, the "room_connected" signal is emitted so that ALL participating rooms
	## can update their "adjacent_rooms" list and "locked" status.
	locked = true
	var all_connectors: Array[Connector]
	# weird trick to cast the type correctly
	all_connectors.assign(get_tree().get_nodes_in_group("Connector"))
	var connector_pair = RoomConnections.find_connector_pairing(get_own_connectors(), all_connectors, 20)
	if len(connector_pair) == 0:
		locked = false
		return false

	var original_position = global_position
	var to = connector_pair[1].global_position - connector_pair[0].global_position
	global_position += to
	room_info.global_position += to
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	for area in overlapping_room_areas:
		if area.is_in_group("RoomArea"):
			global_position = original_position
			print("Tried to snap connectors, but rooms are overlapping.")
			locked = false
			return false

	print("Connectors ({0}) and ({1}) snapped together.".format([str(connector_pair[0]), str(connector_pair[1])]))
	GlobalSignals.room_connected.emit(connector_pair[0], connector_pair[1])

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	for connector in all_connectors:
		if connector in connector_pair:
			continue
		# if another connector has been connected due the room placement, update the participating room's
		# "adjacent_rooms" lists accordingly.
		print(connector.connected_to())
		if connector.connected_to() == connector_pair[0]:
			print("Connectors ({0}) and ({1}) snapped together.".format([str(connector_pair[0]), str(connector)]))
			GlobalSignals.room_connected.emit(connector_pair[0], connector)

	return true


func create_connectors() -> void:
	for connector_pos in RoomData.room_connectors[_shape]:
		var new_connector: Area2D = connector_scene.instantiate()
		connectors_node.add_child(new_connector)
		new_connector.position = connector_pos


func create_navigation_region() -> void:
	## Creates a navigation region for this room (connector regions are made in connector.gd).
	var new_nav_polygon = NavigationPolygon.new()
	new_nav_polygon.agent_radius = 0 # otherwise the shape will be too small to exist!
	new_nav_polygon.add_outline(room_shapes[_shape])
	nav_region.navigation_polygon = new_nav_polygon
	nav_region.bake_navigation_polygon()


func create_texture() -> void:
	texture_polygon.polygon = polygon.polygon
	texture_polygon.color = RoomData.room_colors.pick_random()


func get_own_connectors() -> Array[Connector]:
	## Returns all connectors that are children of this room.
	var all_connectors = get_tree().get_nodes_in_group("Connector")
	var own_connectors: Array[Connector] = []
	for connector in all_connectors:
		# check if connector is a child of this room, and add it to own_connectors
			if connectors_node.is_ancestor_of(connector):
				own_connectors.append(connector)
	return own_connectors


func _on_room_connected(connector1: Connector, connector2: Connector) -> void:
	## If one of the connectors belongs to this room, lock the room, and add the owner of the
	## other connector to this rooms adjacent_rooms list.
	## If the connector belonging to this room is connector2, also delete
	## the connectors NavigationRegion (this has to be done in one of the connectors).
	if connector1 in get_own_connectors():
		locked = true
		var other_room = connector2.get_parent_room()
		adjacent_rooms.append(other_room)
		# TODO: fix this, looks ugly and uses _data which should be private
		room_info.add_adjacent_room(other_room, other_room._data["room_name"])
	elif connector2 in get_own_connectors():
		locked = true
		var other_room = connector1.get_parent_room()
		adjacent_rooms.append(other_room)
		room_info.add_adjacent_room(other_room, other_room._data["room_name"])
		connector2.delete_navigation_region()

		## TODO: ??? Is this necessary, or in the right place?
		await get_tree().physics_frame
		for connector in connector2.get_overlapping_connectors():
			if connector == connector1:
				continue
			print("Deleted connector %s" % [str(connector)])
			connector.queue_free()


func _on_room_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("RoomArea"):
		overlapping_room_areas.append(area)


func _on_room_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("RoomArea"):
		overlapping_room_areas.erase(area)


func _on_room_area_mouse_entered() -> void:
	hovering = true


func _on_room_area_mouse_exited() -> void:
	hovering = false
