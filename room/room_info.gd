extends VBoxContainer
class_name RoomInfo


@export var room_name_label: RichTextLabel
@export var power_usage_label: RichTextLabel
@export var description_popup_label: RichTextLabel



func init_room_info(_data: Dictionary[String, Variant]) -> void:
	#  fills information from _data (positioning is done in main.gd)
	room_name_label.text = _data["room_name"]
	power_usage_label.text = "P" + str(_data["power_usage"])
	description_popup_label.text = _data.get("room_desc", "No description.")


func _process(_delta: float) -> void:
	if description_popup_label.visible:
		## NOTE: Showing/hiding description is done in room.gd.
		description_popup_label.global_position = get_global_mouse_position()
