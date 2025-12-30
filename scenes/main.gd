extends Node2D
class_name Main



@export var nav_actor: Node2D
@export var nav_agent: NavigationAgent2D
@export var path_line: Line2D

@export var room_spawn_area: Area2D
@export var room_spawn_area_polygon: CollisionPolygon2D
@export var texture_polygon: Polygon2D

# All rooms are children of this node
## NOTE: This node has to be above RoomInfoNodes in the node tree,
## otherwise input event propagation won't work correctly!
@export var room_nodes: Node2D
# All room info boxes are children of this node
@export var room_info_nodes: Control

var room_scene = load("res://room/room.tscn")
var room_info_scene = load("res://room/room_info.tscn")

const room_data = RoomData.room_data
var room_inside_spawn_area: bool = false

var spawn_area_color = Color("f3b700")

var all_connectors = []


var path_start: Vector2
var path_start_room: Room # the room where the path starts
var path_end: Vector2
var path_end_room: Room # the room where the path ends



func _ready() -> void:
	spawn_room(RoomData.RoomType.POWER_PLANT)
	create_texture()


func create_texture() -> void:
	texture_polygon.polygon = room_spawn_area_polygon.polygon
	texture_polygon.color = spawn_area_color


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("path_build_mode"):
		GlobalInputFlags.path_build_mode = not GlobalInputFlags.path_build_mode


	if event is InputEventMouseButton and GlobalInputFlags.path_build_mode and event.is_pressed():
		if not path_start:
			path_line.clear_points() # clear the line from previous navigation
			path_start = event.global_position
			for room: Room in get_tree().get_nodes_in_group("Room"):
				if room.hovering:
					# if mouse is inside a room when clicking, that room becomes the starting room
					print(room)
					path_start_room = room
		else:
			path_end = event.global_position
			for room: Room in get_tree().get_nodes_in_group("Room"):
				if room.hovering:
					# if mouse is inside a room when clicking, that room becomes the starting room
					print(room)
					path_end_room = room
			find_path(path_start, path_end)
			var path_length = RoomConnections.distance_between(path_start_room, path_end_room)
			GlobalSignals.path_completed.emit(path_start_room, path_end_room, path_length)
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


func spawn_room(room_type: RoomData.RoomType):
	var new_room: Room = room_scene.instantiate()
	var new_room_data = RoomData.room_data[room_type]
	var new_room_shape = new_room_data["room_shape"]
	new_room.init_room(new_room_data)
	new_room.global_position = room_spawn_area.global_position


	if room_inside_spawn_area:
		print("Cannot spawn new room while existing one is inside spawn area!")
		return

	room_nodes.add_child(new_room)
	for connector in new_room.get_own_connectors():
		all_connectors.append(connector)

	# room info is a child of main scene because otherwise it will rotate with the room
	var new_room_info: RoomInfo = room_info_scene.instantiate()
	new_room_info.init_room_info(RoomData.room_data[room_type])
	new_room_info.global_position = new_room.global_position + RoomData.room_info_pos[new_room_shape]
	# room is responsible for moving info box with the room itself,
	# so it needs a reference of it
	new_room.room_info = new_room_info
	room_info_nodes.add_child(new_room_info)


func find_path(from: Vector2, to: Vector2) -> void:
	## Find path between two positions.
	nav_actor.global_position = from
	nav_agent.set_target_position(to)
	if not nav_agent.is_target_reachable():
		print("Position (%s) is not reachable from position (%s)!" % [str(to), str(from)])


func _on_room_spawn_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("RoomArea"):
		room_inside_spawn_area = true


func _on_room_spawn_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("RoomArea"):
		room_inside_spawn_area = false
