extends CanvasLayer


@onready var main: Main = get_parent()


func _on_command_room_button_pressed() -> void:
	main.spawn_room(RoomData.RoomType.COMMAND_ROOM)


func _on_power_plant_button_pressed() -> void:
	main.spawn_room(RoomData.RoomType.POWER_PLANT)
