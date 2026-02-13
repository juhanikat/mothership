class_name EventFunctions
extends Script


const EVENTS = EventData.EVENTS
const CHOICES = EventData.CHOICES
const RoomType = RoomData.RoomType


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
			var selected_event_data = EventData.event_data[event].duplicate()
			match event:
				EVENTS.POWER_PLANT_MAINTENANCE_1:
					var random_power_plant = scene_tree.get_nodes_in_group(str(RoomType.POWER_PLANT)) \
					.filter(func(room: Room): return room.gameplay.activated) \
					.pick_random()
					assert(random_power_plant is Room)
					selected_event_data["affected_rooms"] = [random_power_plant]

			return selected_event_data

	push_error("get_random_event() did not select anything!")
	push_error("Random number was: %d" % [rand_number])
	push_error("The ranges in event_ranges Array were:")
	for event in event_ranges:
		push_error("" .join(event_ranges[event]))
	return {}


static func print_event_info(scene_tree: SceneTree) -> void:
	print("Turn %s" % [str(GlobalVariables.turn)])
	var possible_events_strings = []
	for data: Dictionary in EventData.event_data.values():
		var can_appear_func: Callable = data.get("can_appear_func")
		if can_appear_func.call(scene_tree):
			possible_events_strings.append("%s (Probability number: %d)" % [data["title"], data["probability"]])
	if len(possible_events_strings) == 0:
		print("No events can appear this turn.")
	else:
		if GlobalVariables.events_disabled:
			print("The following events would have a change to appear, but events are currently disabled:")
		else:
			print("The following events have a change to appear:")
		for event_string in possible_events_strings:
			print(event_string)
	print("")


## Called by HUD when a choice button is pressed.
## Does something (modifies the probabilites on other events, etc.) based on the choice.
## If another event has to be shown directly after this, this function will return the data dict of that event,
## and HUD will call show_event() again.
static func handle_choice(choice: EventData.CHOICES, affected_rooms = null) -> Variant:
	match choice:
		CHOICES.PPM_1_A:
			assert(len(affected_rooms) == 1)
			var power_plant_deactivated = affected_rooms[0].gameplay.deactivate_room()
			if not power_plant_deactivated:
				return EventData.event_data[EVENTS.POWER_PLANT_MAINTENANCE_2_FAILURE]
	return null
