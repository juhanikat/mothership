extends VBoxContainer
class_name RoomInfo


@export var room_name_label: RichTextLabel
@export var power_usage_label: RichTextLabel



func init_room_info(_data) -> void:
	#  fills information from _data (positioning is done in main.gd)
	room_name_label.text = _data["room_name"]
	power_usage_label.text = "P" + str(_data["power_usage"])


func _ready() -> void:
	pass
