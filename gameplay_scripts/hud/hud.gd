class_name Hud
extends CanvasLayer

@export var crew_room_list: ItemList
@export var maintenance_room_list: ItemList
@export var luxury_room_list: ItemList
@export var special_room_list: ItemList
@export var emergency_room_list: ItemList
@export var research_room_list: ItemList
@export var help_popup: PopupPanel
@export var cargo_popup: PopupPanel
@export var cargo_options_box: HBoxContainer
@export var path_build_mode_label: RichTextLabel
@export var path_info_label: RichTextLabel
@export var total_crew_amount_label: RichTextLabel
@export var crew_quarters_limit_label: RichTextLabel
@export var delivery_info_label: RichTextLabel

@export var dev_toolbar: HBoxContainer
@export var dev_options_hint_label: RichTextLabel
@export var disable_events_toggle: CheckButton

@export var next_turn_button: Button

@export var room_selection: RoomSelection
@export var event_popup: EventPopup

var total_crew: int = 0 # changed by the update() function in this script
var crew_quarters_limit: int

@onready var main: Main = get_parent()
@onready var room_category_to_item_list = {
	RoomData.RoomCategory.CREW_ROOM: crew_room_list,
	RoomData.RoomCategory.MAINTENANCE_ROOM: maintenance_room_list,
	RoomData.RoomCategory.LUXURY_ROOM: luxury_room_list,
	RoomData.RoomCategory.SPECIAL_ROOM: special_room_list,
	RoomData.RoomCategory.EMERGENCY_ROOM: emergency_room_list,
	RoomData.RoomCategory.RESEARCH_ROOM: research_room_list,
}


func _ready() -> void:
	GlobalSignals.path_build_mode_toggled.connect(_on_path_build_mode_toggled)
	GlobalSignals.path_completed.connect(_on_path_completed)
	GlobalSignals.crew_quarters_limit_raised.connect(_on_crew_quarters_limit_raised)
	GlobalSignals.crew_quarters_limit_lowered.connect(_on_crew_quarters_limit_lowered)

	GlobalSignals.cargo_bay_order_made.connect(_on_delivery_status_changed)
	GlobalSignals.delivery_status_changed.connect(_on_delivery_status_changed)

	path_build_mode_label.text = "Path build mode: OFF"
	path_info_label.text = "No path yet"
	delivery_info_label.text = "No deliveries in progress."

	for room_data in RoomData.room_data.values():
		room_category_to_item_list[room_data["room_category"]].add_item(room_data["room_name"])

	for item_list: ItemList in room_category_to_item_list.values():
		item_list.item_selected.connect(_on_room_list_item_selected.bind(item_list))

	crew_room_list.select(0)

	crew_quarters_limit = main.crew_quarters_limit
	crew_quarters_limit_label.text = "Crew Quarters limit: %s" % [str(crew_quarters_limit)]

	# hidden by default, press D to show in-game!
	dev_toolbar.hide()
	dev_options_hint_label.show()
	disable_events_toggle.set_pressed_no_signal(GlobalVariables.events_disabled)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("show_dev_toolbar"):
		dev_options_hint_label.hide()
		dev_toolbar.show()


func find_room_data_by_name(room_name: String) -> Dictionary:
	for room_data in RoomData.room_data.values():
		if room_data["room_name"] == room_name:
			return room_data
	push_error("Could not find room by name: %s" % [room_name])
	return { }


func show_cargo_popup(cargo_bay: Room) -> void:
	for button: Button in cargo_options_box.get_children():
		if len(button.pressed.get_connections()) > 0:
			button.pressed.disconnect(_on_cargo_options_button_pressed)
		button.pressed.connect(_on_cargo_options_button_pressed.bind(button.text, cargo_bay))
	cargo_popup.popup()


func _on_path_build_mode_toggled(new_path_build_mode: bool) -> void:
	var mode_text = ""
	if new_path_build_mode == true:
		mode_text = "ON"
	else:
		mode_text = "OFF"
	path_build_mode_label.text = "Path build mode: %s" % [mode_text]


func _on_path_completed(path_start_room: Room, path_end_room: Room, path_length: int) -> void:
	path_info_label.text = "Path starts at room \n%s and ends at room \n%s, with length %s" % [str(path_start_room), str(path_end_room), str(path_length)]


func _on_add_room_button_pressed() -> void:
	for item_list: ItemList in room_category_to_item_list.values():
		if len(item_list.get_selected_items()) > 0:
			var selected_room = item_list.get_item_text(item_list.get_selected_items()[0])
			var selected_room_data = find_room_data_by_name(selected_room)
			main.spawn_room_at_mouse(selected_room_data)


func _on_show_tooltips_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		GlobalInputFlags.show_tooltips = true
	else:
		GlobalInputFlags.show_tooltips = false


func _on_next_turn_button_pressed() -> void:
	if not main.check_turn_requirements():
		return
	if GlobalVariables.room_is_picked:
		return
	GlobalSignals.turn_advanced.emit()


func update_crew_amount_label(crew_change: int) -> void:
	total_crew += crew_change
	total_crew_amount_label.text = "Total crew: %s" % [str(total_crew)]


func _on_crew_quarters_limit_raised(amount: int) -> void:
	crew_quarters_limit += amount
	crew_quarters_limit_label.text = "Crew Quarters limit: %s" % [str(crew_quarters_limit)]


func _on_crew_quarters_limit_lowered(amount: int) -> void:
	crew_quarters_limit -= amount
	crew_quarters_limit_label.text = "Crew Quarters limit: %s" % [str(crew_quarters_limit)]


func _on_room_list_item_selected(_index: int, current_item_list: ItemList) -> void:
	for item_list: ItemList in room_category_to_item_list.values():
		if item_list != current_item_list:
			item_list.deselect_all()


func _on_cargo_options_button_pressed(cargo_type: String, cargo_bay: Room) -> void:
	# sets cargo type depending on the text of the Button pressed
	main.order_cargo(cargo_type, cargo_bay)
	cargo_popup.hide()


func _on_delivery_status_changed(new_status: Dictionary) -> void:
	if new_status.turns_left == 0:
		delivery_info_label.text = "No deliveries in progress."
	else:
		delivery_info_label.text = "Delivering %s, turns left: %s" % [new_status.type, str(new_status.turns_left)]


func _on_help_button_pressed() -> void:
	help_popup.show()


func _on_disable_events_button_toggled(toggled_on: bool) -> void:
	GlobalVariables.events_disabled = toggled_on
