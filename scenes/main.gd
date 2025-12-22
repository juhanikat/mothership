extends Node2D
class_name Main



@export var nav_actor: Node2D
@export var nav_agent: NavigationAgent2D
@export var path_line: Line2D

@export var room_spawn_area: Area2D
var room_scene = load("res://scenes/room.tscn")

const room_data = RoomData.room_data
var room_inside_spawn_area: bool = false

var all_connectors = []


var path_start: Vector2
var path_end: Vector2



func _ready() -> void:
	spawn_room(RoomData.RoomType.POWER_PLANT)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("path_build_mode"):
		GlobalInputFlags.path_build_mode = not GlobalInputFlags.path_build_mode


	if event is InputEventMouseButton and GlobalInputFlags.path_build_mode and event.is_pressed():
		if not path_start:
			path_start = event.global_position
		else:
			path_end = event.global_position
			find_path(path_start, path_end)
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
	new_room.init_room(RoomData.room_data[room_type])
	new_room.global_position = room_spawn_area.position

	if room_inside_spawn_area:
		print("Cannot spawn new room while existing one is inside spawn area!")
		return

	add_child(new_room)
	for connector in new_room.get_own_connectors():
		all_connectors.append(connector)


func find_path(from: Vector2, to: Vector2) -> void:
	## Find path between two positions.
	nav_actor.global_position = from
	path_line.clear_points() # clear the line from previous navigation
	nav_agent.set_target_position(to)
	if not nav_agent.is_target_reachable():
		print("Position (%s) is not reachable from position (%s)!" % [str(to), str(from)])


func _on_room_spawn_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("RoomClickableArea"):
		room_inside_spawn_area = true


func _on_room_spawn_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("RoomClickableArea"):
		room_inside_spawn_area = false
