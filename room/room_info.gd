extends PanelContainer
class_name RoomInfo


@export var room_name_label: RichTextLabel
@export var power_usage_label: RichTextLabel

@export var adjacent_rooms_popup_label: RichTextLabel
@export var description_popup_label: RichTextLabel



func init_room_info(_data: Dictionary[String, Variant]) -> void:
	#  fills information from _data (positioning is done in main.gd)
	room_name_label.text = _data["room_name"]
	power_usage_label.text = "P" + str(_data["power_usage"])
	description_popup_label.text = _data.get("room_desc", "No description.")
	adjacent_rooms_popup_label.text = "No adjacent rooms."


func _process(_delta: float) -> void:
	if description_popup_label.visible:
		## NOTE: Showing/hiding description is done in room.gd.
		description_popup_label.global_position = get_global_mouse_position()


func update_adjacent_rooms_label(rooms: Array[Room]) -> void:
	## Called by room.gd to update the adjacent rooms popup.
	adjacent_rooms_popup_label.text = "Adjacent rooms (%s):\n" % [str(len(rooms))]
	for room in rooms:
		adjacent_rooms_popup_label.text += "\n%s (%s)" % [str(room), str(room._data["room_name"])]
