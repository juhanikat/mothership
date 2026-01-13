extends PanelContainer
class_name RoomInfo


@export var room_name_label: RichTextLabel
@export var power_usage_label: RichTextLabel
@export var traits_label: RichTextLabel
@export var power_supply_label: RichTextLabel

@export var adjacent_rooms_label: RichTextLabel
@export var description_label: RichTextLabel


##  fills information from _data (positioning is done in main.gd).
## NOTE: showing/hiding information that is visible when hovering room is done in room.gd.
func init_room_info(_data: Dictionary[String, Variant], overwrite_name: String = "") -> void:
	if overwrite_name:
		room_name_label.text = overwrite_name
	else:
		room_name_label.text = _data["room_name"]

	var power_usage = _data["power_usage"]
	if power_usage == 0:
		power_usage_label.text = ""
		traits_label.text += "Does not consume power. \n"
	else:
		power_usage_label.text = "Consumes %s power." %  [str(power_usage)]

	if "always_activated" in _data:
		traits_label.text += "Always active. \n"

	description_label.text = _data.get("room_desc", "No description.")
	adjacent_rooms_label.text = "No adjacent rooms."

	if "power_supply" in _data.keys():
		power_supply_label.text = "Supplies power to rooms in range of %s (%s remaining)" % \
		[str(_data["power_supply"]["range"]), str(_data["power_supply"]["capacity"])]


func shrink_panel_container() -> void:
	size = get_minimum_size()


## Called by room.gd to update the adjacent rooms popup.
func update_adjacent_rooms_label(rooms: Array[Room]) -> void:
	adjacent_rooms_label.text = "Adjacent rooms (%s):" % [str(len(rooms))]
	for room in rooms:
		adjacent_rooms_label.text += "\n%s" % [room.room_info.room_name_label.text]


## Called by room.gd to update the power supply label when rooms toggle power.
func update_power_supply_label(current_power_supply: Dictionary) -> void:
	power_supply_label.text = "Supplies power to rooms in range of %s (%s remaining)" % \
		[str(current_power_supply["range"]), str(current_power_supply["capacity"])]
