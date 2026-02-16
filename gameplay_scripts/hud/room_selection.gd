extends CanvasLayer
class_name RoomSelection


@export var order_description_label: RichTextLabel
@export var room_container: HBoxContainer
@onready var main: Node2D = get_tree().root.get_node("Main")


func clear_room_buttons() -> void:
	for button in room_container.get_children():
		button.queue_free()


## Adds one or more room buttons to the side panel (change this to have pictures of the rooms later).
## Also show the description of the order.
func show_order(description: String, room_data_array: Array[Dictionary]) -> void:
	order_description_label.text = "\"%s\"" % [description]
	for room_data in room_data_array:
		var new_room_button = Button.new()
		var button_text_color = RoomData.room_colors[room_data["room_category"]]
		new_room_button.add_theme_color_override("font_color", button_text_color)
		new_room_button.text = "%s" % [room_data["room_name"]]
		new_room_button.pressed.connect(_on_room_button_pressed.bind(room_data))
		new_room_button.focus_mode = Control.FOCUS_NONE
		room_container.add_child(new_room_button)


func _on_room_button_pressed(room_data: Dictionary) -> void:
	main.spawn_room_at_mouse(room_data)
