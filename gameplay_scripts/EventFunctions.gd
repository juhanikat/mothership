class_name EventFunctions
extends Script


## Returns a random events data from a pool of possible events, by first checking each events "can_appear_func" status,
## then picking a random event from that pool by using their "probability" value (bigger number = better chance to get picked)
static func get_random_event(scene_tree: SceneTree) -> Dictionary:
	var event_ranges: Dictionary[EventData.EVENTS, Array] = {}
	var max_number = 0
	for event: EventData.EVENTS in EventData.event_data:
		var data = EventData.event_data[event]
		var can_appear_func: Callable = data.get("can_appear_func")
		if can_appear_func.call(scene_tree):
			event_ranges[event] = range(max_number, data["probability"] + max_number)
			max_number += data["probability"]

	if len(event_ranges) == 0:
		# No events can appear at the moment
		return {}

	var rand_number = randi_range(0, max_number - 1)
	for event: EventData.EVENTS in event_ranges:
		if rand_number in event_ranges[event]:
			return EventData.event_data[event]

	push_error("get_random_event() did not select anything!")
	push_error("Random number was: %d" % [rand_number])
	push_error("The ranges in event_ranges Array were:")
	for event in event_ranges:
		push_error("" .join(event_ranges[event]))
	return {}


static func print_event_info(scene_tree: SceneTree) -> void:
	var possible_events_strings = []
	for data: Dictionary in EventData.event_data.values():
		var can_appear_func: Callable = data.get("can_appear_func")
		if can_appear_func.call(scene_tree):
			possible_events_strings.append("%s (Probability number: %d)" % [data["title"], data["probability"]])
	if len(possible_events_strings) == 0:
		print("No events can appear this turn.")
	else:
		print("The following events have a change to appear:")
		for event_string in possible_events_strings:
			print(event_string)


## Called by HUD when a choice button is pressed.
## Does something (modifies the probabilites on other events, etc.) based on the choice.
static func handle_choice(choice: EventData.CHOICES) -> void:
	pass
