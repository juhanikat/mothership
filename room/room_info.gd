extends PanelContainer
class_name RoomInfo


@export var room_name_label: RichTextLabel
@export var power_usage_label: RichTextLabel
@export var power_supply_label: RichTextLabel


@export var adjacent_rooms_popup_label: RichTextLabel
@export var description_popup_label: RichTextLabel


##  fills information from _data (positioning is done in main.gd).
func init_room_info(_data: Dictionary[String, Variant]) -> void:
	room_name_label.text = _data["room_name"]
	power_usage_label.text = "P" + str(_data["power_usage"])
	description_popup_label.text = _data.get("room_desc", "No description.")
	adjacent_rooms_popup_label.text = "No adjacent rooms."

	if "power_supply" in _data.keys():
		power_supply_label.text = "Supplies power to rooms in range of %s (%s remaining)" % \
		[str(_data["power_supply"]["range"]), str(_data["power_supply"]["capacity"])]


func _process(_delta: float) -> void:
	if description_popup_label.visible:
		## NOTE: Showing/hiding description is done in room.gd.
		description_popup_label.global_position = get_global_mouse_position()


## Called by room.gd to update the adjacent rooms popup.
func update_adjacent_rooms_label(rooms: Array[Room]) -> void:
	adjacent_rooms_popup_label.text = "Adjacent rooms (%s):\n" % [str(len(rooms))]
	for room in rooms:
		adjacent_rooms_popup_label.text += "\n%s (%s)" % [str(room), str(room._data["room_name"])]


## Called by room.gd to update the power supply label when rooms toggle power.
func update_power_supply_label(current_power_supply: Dictionary) -> void:
	power_supply_label.text = "Supplies power to rooms in range of %s (%s remaining)" % \
		[str(current_power_supply["range"]), str(current_power_supply["capacity"])]
