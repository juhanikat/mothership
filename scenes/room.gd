extends Node2D
class_name Tile

var connector_scene = load("res://scenes/connector.tscn")

@export var room_area: Area2D # actual CollisionPolygon of the tile
@export var polygon: CollisionPolygon2D # actual CollisionPolygon of the tile
@export var all_room_shapes: Area2D # all possible tile types are children of thiis node
@onready var room_shapes: Dictionary[RoomData.RoomShape, PackedVector2Array]
@onready var clickable_area: Area2D


const LShape_dimensions = RoomData.room_shape_dimensions[RoomShape.LShape]
const SquareShape_dimensions = RoomData.room_shape_dimensions[RoomShape.SquareShape]
const RoomShape = RoomData.RoomShape

const MAX_CONNECTOR_DISTANCE = 40

var hovering: bool = false # true when mouse is hovering over this room
var is_picked: bool = false
var locked: bool = false # true once room has been placed and can no longer be moved
var overlapping_room: bool = false # true another room's ClickableArea overlaps this one's
var target_rotation: float = 0

var _shape: RoomData.RoomShape
var _data: Dictionary[String, Variant]


func init_room(i_data: Dictionary[String, Variant]) -> void:
	## Call this before the tile is added to the scene tree.
	_data = i_data
	_shape = _data["room_shape"]

	# creates connectorsd for the room, depending on it's shape
	create_connectors()

	# creates the clickable area for the node, depending on its shape
	create_clickable_area()


func _ready() -> void:
	assert(len(_data.keys()) > 0)

	for room_shape in all_room_shapes.get_children():
		if room_shape.name == "LShapePolygon":
			room_shapes[RoomShape.LShape] = room_shape.polygon
		if room_shape.name == "SquareShapePolygon":
			room_shapes[RoomShape.SquareShape] = room_shape.polygon

	polygon.polygon = room_shapes[_shape]


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return

	if event is InputEventMouseButton and hovering and event.is_pressed():
		# z_index is changed to stop the game picking up two rooms at once
		if is_picked:
			if overlapping_room:
				check_connector_snap()
			else:
				is_picked = false
		else:
			is_picked = true

	if event is InputEventMouseMotion:
		if is_picked:
			var viewport_size = get_viewport_rect().size
			var camera = get_viewport().get_camera_2d()
			# ????? it works
			global_position = ((event.position - Vector2(viewport_size.x/2, viewport_size.y/2))/ camera.zoom) + camera.position

	elif event.is_action_pressed("rotate_tile") and is_picked:
			target_rotation += 90
			#snap_to()


func _process(delta: float) -> void:
	rotation_degrees = lerpf(rotation_degrees, target_rotation, 0.15)
	#snap rotation to target value once close enough, might prevent some bugs with rounding
	if abs(rotation_degrees - target_rotation) < 0.05:
		rotation_degrees = target_rotation


func get_room_center() -> Vector2:
	if _shape == RoomShape.LShape:
		return LShape_dimensions / 2
	elif _shape == RoomShape.SquareShape:
		return SquareShape_dimensions / 2

	push_error("ERROR: Invalid tile type given!")
	return Vector2(0, 0)


func create_clickable_area() -> void:
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	if _shape == RoomShape.LShape:
		shape.size = LShape_dimensions * 2
	elif _shape == RoomShape.SquareShape:
		shape.size = SquareShape_dimensions * 2
	else:
		push_error("Room shape (" + str(_shape) + ") did not match any enum!")

	collision.shape = shape
	area.add_child(collision)
	area.area_entered.connect(_on_clickable_area_area_entered)
	area.area_exited.connect(_on_clickable_area_area_exited)
	area.mouse_entered.connect(_on_clickable_area_mouse_entered)
	area.mouse_exited.connect(_on_clickable_area_mouse_exited)
	area.add_to_group("RoomClickableArea")
	area.name = "ClickableArea"
	add_child(area)


func create_connectors() -> void:
	for connector_pos in RoomData.room_connectors[_shape]:
		var new_connector: Area2D = connector_scene.instantiate()
		add_child(new_connector)
		new_connector.position = connector_pos


func get_own_connectors() -> Array[Area2D]:
	## Returns all connectors that are children of this room.
	var all_connectors = get_tree().get_nodes_in_group("Connector")
	var own_connectors: Array[Area2D] = []
	for connector in all_connectors:
		# check if connector is a child of this room, and add it to own_connectors
			if is_ancestor_of(connector):
				own_connectors.append(connector)
	return own_connectors


func check_connector_snap() -> void:
	## loop through all connectors (in the entire game),
	## and find first two connectors that are in range of each other.
	## If found, snap them together.
	var all_connectors = get_tree().get_nodes_in_group("Connector")
	var own_connectors = get_own_connectors()
	var closest_pair = []
	var closest_pair_distance = null
	for own_connector: Area2D in own_connectors:
		for other_connector: Area2D in all_connectors:
			if other_connector in own_connectors:
				continue
			var distance = own_connector.global_position.distance_to(other_connector.global_position)
			if distance < MAX_CONNECTOR_DISTANCE and (len(closest_pair) == 0 or distance < closest_pair_distance):
				closest_pair = [own_connector, other_connector]
				closest_pair_distance = distance
	if closest_pair:
		snap_connectors(closest_pair[0], closest_pair[1])
	return


func snap_connectors(own_connector: Area2D, other_connector: Area2D):
	## Snaps two connectors together, and locks this room in place.
	var to = other_connector.global_position - own_connector.global_position
	print(to)
	position += to
	locked = true


func _on_clickable_area_area_entered(area: Area2D) -> void:
	## When any area is inside this room's ClickableArea, you cannot place the room
	if area.is_in_group("RoomClickableArea"):
		overlapping_room = true


func _on_clickable_area_area_exited(area: Area2D) -> void:
	## The ClickableArea is larger than the area used for the actual tile
	if area.is_in_group("RoomClickableArea"):
		overlapping_room = false


func _on_clickable_area_mouse_entered() -> void:
	## The ClickableArea is larger than the area used for the actual tile
	hovering = true


func _on_clickable_area_mouse_exited() -> void:
	## The ClickableArea is larger than the area used for the actual tile
	hovering = false
