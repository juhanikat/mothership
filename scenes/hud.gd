extends CanvasLayer


@export var room_list: ItemList
@export var path_build_mode_label: RichTextLabel
@export var path_info_label: RichTextLabel
@export var total_crew_amount_label: RichTextLabel
@export var crew_quarters_limit_label: RichTextLabel

@onready var main: Main = get_parent()

var total_crew: int = 0
var crew_quarters_limit: int


func _ready() -> void:
	GlobalSignals.path_build_mode_toggled.connect(_on_path_build_mode_toggled)
	GlobalSignals.path_completed.connect(_on_path_completed)
	GlobalSignals.crew_added.connect(_on_crew_added)
	GlobalSignals.crew_removed.connect(_on_crew_removed)
	GlobalSignals.crew_quarters_limit_raised.connect(_on_crew_quarters_limit_raised)
	GlobalSignals.crew_quarters_limit_lowered.connect(_on_crew_quarters_limit_lowered)
	path_build_mode_label.text = "Path build mode: OFF"
	path_info_label.text = "No path yet"

	for room_data in RoomData.room_data.values():
		room_list.add_item(room_data["room_name"])

	room_list.select(0)

	crew_quarters_limit = main.crew_quarters_limit
	crew_quarters_limit_label.text = "Crew Quarters limit: %s" % [str(crew_quarters_limit)]


func find_room_data_by_name(room_name: String) -> Dictionary:
	for room_data in RoomData.room_data.values():
		if room_data["room_name"] == room_name:
			return room_data
	push_error("Could not find room by name: %s" % [room_name])
	return {}


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
	var selected_room = room_list.get_item_text(room_list.get_selected_items()[0])
	var selected_room_data = find_room_data_by_name(selected_room)
	main.spawn_room(selected_room_data)


func _on_show_tooltips_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		GlobalInputFlags.show_tooltips = true
	else:
		GlobalInputFlags.show_tooltips = false


func _on_next_turn_button_pressed() -> void:
	main.next_turn()


func _on_crew_added(amount: int) -> void:
	total_crew += amount
	total_crew_amount_label.text = "Crew amount: %s" % [str(total_crew)]


func _on_crew_removed(amount: int) -> void:
	total_crew -= amount
	total_crew_amount_label.text = "Crew amount: %s" % [str(total_crew)]


func _on_crew_quarters_limit_raised(amount: int) -> void:
	crew_quarters_limit += amount
	crew_quarters_limit_label.text = "Crew Quarters limit: %s" % [str(crew_quarters_limit)]


func _on_crew_quarters_limit_lowered(amount: int) -> void:
	crew_quarters_limit -= amount
	crew_quarters_limit_label.text = "Crew Quarters limit: %s" % [str(crew_quarters_limit)]
