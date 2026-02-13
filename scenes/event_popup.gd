class_name EventPopup
extends CanvasLayer

@export var event_title_label: RichTextLabel
@export var event_description_label: RichTextLabel
@export var event_choice_button_container: VBoxContainer
@export var close_button: Button

@onready var hud = get_parent()



func _ready() -> void:
	for button in event_choice_button_container.get_children():
		button.queue_free()
	hide()

func show_event(event_data: Dictionary) -> void:
	if GlobalVariables.events_disabled:
		return
	for existing_button in event_choice_button_container.get_children():
		existing_button.queue_free()

	event_title_label.text = event_data["title"]
	event_description_label.text = event_data["description"]
	var affected_rooms = event_data.get("affected_rooms")
	if affected_rooms:
		var room_names = affected_rooms.map(func(room: Room): return room.room_name)
		event_description_label.text += "Affected rooms: %s" % [", ".join(room_names)]
	var choices = event_data.get("choices", null)
	if choices:
		# disable next turn button and force popup to be shown until a choice is made
		hud.next_turn_button.disabled = true
		close_button.disabled = true
		for choice in choices:
			var choice_button = Button.new()
			choice_button.text = choice.text
			choice_button.pressed.connect(_on_choice_button_pressed.bind(choice.value, affected_rooms))
			event_choice_button_container.add_child(choice_button)
	show()


func _on_choice_button_pressed(choice_value: EventData.CHOICES, affected_rooms) -> void:
	hud.next_turn_button.disabled = false
	close_button.disabled = false
	var returned_event_data = EventFunctions.handle_choice(choice_value, affected_rooms)
	if returned_event_data:
		# if handle_choice() returns a new event_data, handle that event immediately
		show_event(returned_event_data)
	hide()


func _on_close_button_pressed() -> void:
	hide()
