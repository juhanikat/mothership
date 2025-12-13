extends Node2D
class_name Main


var room_scene = load("res://scenes/room.tscn")
var room_spawn_pos: Vector2 = Vector2(0, 0)

const room_data = RoomData.room_data

func _ready() -> void:
	spawn_room(RoomData.RoomType.COMMAND_ROOM)




func spawn_room(room_type: RoomData.RoomType):
	var new_room = room_scene.instantiate()
	new_room.init_room(RoomData.room_data[room_type])
	for room in get_tree().get_nodes_in_group("Tile"):
		if room.global_position == room_spawn_pos:
			print("Cannot spawn new room on top of existing one")
			return

	new_room.global_position = room_spawn_pos
	add_child(new_room)
