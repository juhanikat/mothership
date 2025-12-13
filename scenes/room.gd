extends Node2D
class_name Tile



@export var tile_area: Area2D # actual CollisionPolygon of the tile
@export var polygon: CollisionPolygon2D # actual CollisionPolygon of the tile
@export var all_tile_shapes: Area2D # all possible tile types are children of thiis node
@onready var tile_shapes: Dictionary[RoomData.RoomShape, PackedVector2Array]
@onready var clickable_area: Area2D


const LShape_dimensions = RoomData.LShape_dimensions
const SquareShape_dimensions = RoomData.SquareShape_dimensions
const RoomShape = RoomData.RoomShape


var is_picked: bool = false
var rotation_point: Area2D
var target_rotation: float = 0

var _shape: RoomData.RoomShape # set this when spawning tile
var _data: Dictionary[String, Variant]


func init_room(i_data: Dictionary[String, Variant]) -> void:
	## Call this before the tile is added to the scene tree.
	_data = i_data
	_shape = _data["room_shape"]


func _ready() -> void:
	assert(len(_data.keys()) > 0)

	for tile_shape in all_tile_shapes.get_children():
		if tile_shape.name == "LShapePolygon":
			tile_shapes[RoomShape.LShape] = tile_shape.polygon
		if tile_shape.name == "SquarePolygon":
			tile_shapes[RoomShape.SquareShape] = tile_shape.polygon

	polygon.polygon = tile_shapes[_shape]

	# creates the clickable area for the node, depending on its shape
	clickable_area = get_clickable_area()
	add_child(clickable_area)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_picked:
		var viewport_size = get_viewport_rect().size
		var camera = get_viewport().get_camera_2d()
		# ????? it works
		global_position = ((event.position - Vector2(viewport_size.x/2, viewport_size.y/2))/ camera.zoom) + camera.position - get_room_center()

	if event.is_action_pressed("rotate_tile") and is_picked:
		target_rotation += 90
		#snap_to()



func _process(delta: float) -> void:
	if rotation_point:
		rotation_point.rotation_degrees = lerpf(rotation_point.rotation_degrees, target_rotation, 0.15)
		#snap rotation to target value once close enough, might prevent some bugs with rounding
		if abs(rotation_point.rotation_degrees - target_rotation) < 0.05:
			rotation_point.rotation_degrees = target_rotation


func get_room_center() -> Vector2:
	if _shape == RoomShape.LShape:
		return LShape_dimensions / 2
	elif _shape == RoomShape.SquareShape:
		return SquareShape_dimensions / 2

	push_error("ERROR: Invalid tile type given!")
	return Vector2(0, 0)

func get_clickable_area() -> Area2D:
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	if _shape == RoomShape.LShape:
		area.position = LShape_dimensions / 2
		shape.size = LShape_dimensions * 2
	elif _shape == RoomShape.SquareShape:
		area.position = SquareShape_dimensions / 2
		shape.size = SquareShape_dimensions * 2
	else:
		push_error("Room shape (" + str(_shape) + ") did not match any enum!")

	collision.shape = shape
	area.add_child(collision)
	area.input_event.connect(_on_clickable_area_input_event)
	return area


func snap_to() -> void:
	var closest_tile = null
	for tile in get_tree().get_nodes_in_group("Tile"):
		# find closest tile
		if tile == self:
			continue
		if !closest_tile or position.distance_to(tile.position) < position.distance_to(closest_tile.position):
			closest_tile = tile
	if closest_tile:
		print(closest_tile.type)

func _on_clickable_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	## The ClickableArea is larger than the area used for the actual tile
	if event is InputEventMouseButton and event.is_pressed():
		if is_picked:
			is_picked = false
		else:
			is_picked = true
			var new_rotation_point = Area2D.new()
			if rotation_point:
				new_rotation_point.rotation_degrees = rotation_point.rotation_degrees
				rotation_point.queue_free()

			rotation_point = new_rotation_point
			var collision = CollisionShape2D.new()
			collision.shape = RectangleShape2D.new()
			collision.shape.size = Vector2(16, 16)
			rotation_point.add_child(collision)


			add_child(rotation_point)
			rotation_point.position = get_room_center()
			tile_area.reparent(rotation_point)
