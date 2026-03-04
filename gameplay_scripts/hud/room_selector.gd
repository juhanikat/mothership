extends CanvasLayer

class_name RoomSelector

@export var room_container: HBoxContainer
@onready var main: Main = get_tree().root.get_node("Main")

const RoomType = RoomData.RoomType
const RoomCategory = RoomData.RoomCategory

enum RoomSelection { STARTING_SELECTION }
const starting_selection = [
	RoomType.HALLWAY,
	RoomType.POWER_PLANT,
	RoomType.CREW_QUARTERS,
	RoomType.CANTEEN,
	RoomType.RATION_STORAGE,
	RoomType.LAVATORY,
	RoomType.DATA_ANALYSIS,
]

# this is updated through the game
var current_selection = []


static func room_sort(a: Dictionary, b: Dictionary) -> bool:
	var category_preference = [
		RoomCategory.CREW_ROOM,
		RoomCategory.MAINTENANCE_ROOM,
		RoomCategory.EMERGENCY_ROOM,
		RoomCategory.RESEARCH_ROOM,
		RoomCategory.LUXURY_ROOM,
		RoomCategory.SPECIAL_ROOM,
	]
	if category_preference.find(a.room_category) > category_preference.find(b.room_category):
		return false
	elif category_preference.find(a.room_category) == category_preference.find(b.room_category):
		var names = [a, b].map(func(room_data): return room_data.room_name)
		names.sort()
		if names.find(a.room_name) > names.find(b.room_name):
			return false
		return true
	return true


func _ready() -> void:
	GlobalSignals.room_connected.connect(_on_room_connected)
	current_selection += starting_selection


func clear_room_buttons() -> void:
	for button in room_container.get_children():
		button.queue_free()


func show_selection() -> void:
	clear_room_buttons()

	var room_data_array = []
	for room_type in current_selection:
		room_data_array.append(RoomData.room_data[room_type])

	room_data_array.sort_custom(room_sort)

	for room_data in room_data_array:
		var new_room_button = Button.new()
		var button_text_color = RoomData.room_colors[room_data["room_category"]]
		new_room_button.add_theme_color_override("font_color", button_text_color)
		new_room_button.text = "%s \n\n Cost: %s" % [room_data["room_name"], room_data["resource_cost"]]
		new_room_button.pressed.connect(_on_room_button_pressed.bind(room_data))
		new_room_button.focus_mode = Control.FOCUS_NONE
		room_container.add_child(new_room_button)


func add_rooms_to_selection(new_rooms: Array[RoomType]) -> void:
	current_selection += new_rooms


func _on_room_connected(connector1: Connector, _connector2: Connector) -> void:
	if connector1.get_parent_room().room_type == RoomType.AOR:
		add_rooms_to_selection([RoomType.CARGO_BAY])
	show_selection()


func _on_room_button_pressed(room_data: Dictionary) -> void:
	main.spawn_room_at_mouse(room_data)
