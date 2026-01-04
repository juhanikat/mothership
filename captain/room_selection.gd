extends CanvasLayer
class_name RoomSelection

@export var room_container: VBoxContainer
@onready var main: Node2D = get_tree().root.get_node("Main")



func clear_room_buttons() -> void:
	for button in room_container.get_children():
		button.queue_free()


## Adds one or more room buttons to the side panel (change this to have pictures of the rooms later).
func add_room_buttons(room_data_array: Array[Dictionary]) -> void:
	for room_data in room_data_array:
		var new_room_button = Button.new()
		new_room_button.text = room_data["room_name"]
		new_room_button.pressed.connect(_on_room_button_pressed.bind(room_data))
		new_room_button.focus_mode = Control.FOCUS_NONE
		room_container.add_child(new_room_button)


func _on_room_button_pressed(room_data: Dictionary) -> void:
	main.spawn_room_at_mouse(room_data)
