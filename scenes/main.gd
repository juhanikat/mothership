extends Node2D
class_name Main

@export var room_spawn_area: Area2D
var room_scene = load("res://scenes/room.tscn")

const room_data = RoomData.room_data
var room_inside_spawn_area: bool = false


func _ready() -> void:
	spawn_room(RoomData.RoomType.POWER_PLANT)


func spawn_room(room_type: RoomData.RoomType):
	var new_room = room_scene.instantiate()
	new_room.init_room(RoomData.room_data[room_type])
	new_room.global_position = room_spawn_area.position

	if room_inside_spawn_area:
		print("Cannot spawn new room while existing one is inside spawn area!")
		return

	add_child(new_room)


func _on_room_spawn_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("RoomClickableArea"):
		room_inside_spawn_area = true


func _on_room_spawn_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("RoomClickableArea"):
		room_inside_spawn_area = false
