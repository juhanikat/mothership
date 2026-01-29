class_name RoomInfo
extends PanelContainer

@export var assigned_crew_members_container: HBoxContainer
@export var living_crew_members_container: HBoxContainer
@export var assigned_crew_members_container_label: RichTextLabel
@export var living_crew_members_container_label: RichTextLabel
@export var room_name_label: RichTextLabel
@export var power_usage_label: RichTextLabel
@export var traits_label: RichTextLabel
@export var resource_label: RichTextLabel
@export var description_label: RichTextLabel
@export var adjacent_rooms_label: RichTextLabel

var crew_member_scene = load("res://scenes/crew_member.tscn")


var parent_room: Room
var relative_pos = Vector2(-150, -75)
var hovering: bool = false

var crew_texture = load("res://icon.svg")

func _ready() -> void:
	description_label.hide()
	adjacent_rooms_label.hide()


## fills information from _data (positioning is done in main.gd).
## NOTE: showing/hiding information that is visible when hovering room is done in room.gd.
func init_room_info(p_room: Room, _data: Dictionary[String, Variant], overwrite_name: String = "") -> void:
	parent_room = p_room
	if overwrite_name:
		room_name_label.text = overwrite_name
	else:
		room_name_label.text = _data["room_name"]

	var power_usage = _data["power_usage"]
	if power_usage == 0:
		power_usage_label.text = ""
		traits_label.text += "Does not consume power. \n"
	else:
		power_usage_label.text = "Consumes %s power." % [str(power_usage)]

	traits_label.text = ""
	if "always_activated" in _data:
		traits_label.text += "Always active. \n"
	if "always_deactivated" in _data:
		traits_label.text += "Cannot be activated. \n"

	resource_label.text = ""

	description_label.text = _data.get("room_desc", "No description.")
	adjacent_rooms_label.text = "No adjacent rooms."

	if "power_supply" in _data.keys():
		resource_label.text = "Supplies power to rooms in range of %s (%s remaining)" % \
		[str(_data["power_supply"]["range"]), str(_data["power_supply"]["capacity"])]

	if "fuel_amount" in _data:
		resource_label.text = "%s fuel remaining." % [str(_data["fuel_amount"])]

	if "rations_amount" in _data:
		resource_label.text = "%s rations remaining." % [str(_data["rations_amount"])]


## Called by room.gd when this room is hovered over.
func expand_info() -> void:
	#global_position += relative_pos
	description_label.show()
	adjacent_rooms_label.show()
	z_index = 2
	offset_right += 100

	for info_node in get_tree().get_nodes_in_group("RoomInfo"):
		if info_node == self:
			continue
		info_node.hide()

	#var stylebox: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	#stylebox.set("bg_color", Color(0.0, 0.0, 0.0, 1.0))
	#add_theme_stylebox_override("panel", stylebox)


func shrink_info() -> void:
	#global_position = parent_room.global_position + RoomData.room_info_pos[parent_room._shape]
	description_label.hide()
	adjacent_rooms_label.hide()
	z_index = 0
	reset_size()

	var stylebox: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	stylebox.set("bg_color", Color(0.0, 0.0, 0.0, 0.0))
	add_theme_stylebox_override("panel", stylebox)

	for info_node in get_tree().get_nodes_in_group("RoomInfo"):
		if info_node == self:
			continue
		info_node.show()


## Called by room.gd to update the adjacent rooms popup.
func update_adjacent_rooms_label(rooms: Array[Room]) -> void:
	adjacent_rooms_label.text = "Adjacent rooms (%s):" % [str(len(rooms))]
	for room in rooms:
		adjacent_rooms_label.text += "\n%s" % [room.room_info.room_name_label.text]


func update_power_supply_label(current_power_supply: Dictionary) -> void:
	resource_label.text = "Supplies power to rooms in range of %s (%s remaining)" % \
	[str(current_power_supply["range"]), str(current_power_supply["capacity"])]


func update_fuel_remaining_label(current_fuel_remaining: int) -> void:
	resource_label.text = "%s fuel remaining." % [str(current_fuel_remaining)]


func update_rations_remaining_label(current_rations_remaining: int) -> void:
	resource_label.text = "%s rations remaining." % [str(current_rations_remaining)]


func update_assigned_crew_container(current_crew: Array[CrewMember]) -> void:
	for label in assigned_crew_members_container.get_children():
		label.queue_free()
	for crew_member in current_crew:
		var crew_name_label = RichTextLabel.new()
		crew_name_label.text = crew_member.crewmember_name
		crew_name_label.fit_content = true
		crew_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		crew_name_label.add_theme_font_size_override("normal", 7)
		crew_name_label.add_theme_constant_override("outline_size", 3)
		parent_room.room_info.assigned_crew_members_container.add_child(crew_name_label)


func update_living_crew_container(current_crew: Array[CrewMember]) -> void:
	for label in living_crew_members_container.get_children():
		label.queue_free()
	for crew_member in current_crew:
		var crew_name_label = RichTextLabel.new()
		crew_name_label.text = crew_member.crewmember_name
		crew_name_label.fit_content = true
		crew_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		crew_name_label.add_theme_font_size_override("normal", 7)
		crew_name_label.add_theme_constant_override("outline_size", 3)
		parent_room.room_info.living_crew_members_container.add_child(crew_name_label)
