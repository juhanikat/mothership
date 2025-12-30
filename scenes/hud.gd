extends CanvasLayer


@export var path_build_mode_label: RichTextLabel
@export var path_info_label: RichTextLabel

@onready var main: Main = get_parent()



func _ready() -> void:
	GlobalSignals.path_build_mode_toggled.connect(_on_path_build_mode_toggled)
	GlobalSignals.path_completed.connect(_on_path_completed)
	path_build_mode_label.text = "Path build mode: OFF"
	path_info_label.text = "No path yet"


func _on_path_build_mode_toggled(new_path_build_mode: bool) -> void:
	var mode_text = ""
	if new_path_build_mode == true:
		mode_text = "ON"
	else:
		mode_text = "OFF"
	path_build_mode_label.text = "Path build mode: %s" % [mode_text]


func _on_path_completed(path_start_room: Room, path_end_room: Room, path_length: int) -> void:
	path_info_label.text = "Path starts at room \n%s and ends at room \n%s, with length %s" % [str(path_start_room), str(path_end_room), str(path_length)]


func _on_command_room_button_pressed() -> void:
	main.spawn_room(RoomData.RoomType.COMMAND_ROOM)


func _on_power_plant_button_pressed() -> void:
	main.spawn_room(RoomData.RoomType.POWER_PLANT)


func _on_crew_quarters_button_pressed() -> void:
	main.spawn_room(RoomData.RoomType.CREW_QUARTERS)
