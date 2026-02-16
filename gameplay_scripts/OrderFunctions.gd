extends Script
class_name OrderFunctions

## Holds functions related to the selection of new rooms and events.
## Actual HUD for the room selection is elsewhere.
## Also check out OrderData.gd.
static var starting_order = OrderData.starting_order.duplicate(true)
static var orders = OrderData.basic_orders.duplicate(true)
static var special_orders = OrderData.special_orders.duplicate(true)


# NOTE: The orders appended to this Array are modified from the original orders!
static var order_history: Array[OrderData.Order] = []

const RoomCategory = RoomData.RoomCategory
const Order = OrderData.Order

static func room_sort(a: Dictionary, b: Dictionary) -> bool:
	var category_preference = [
		RoomCategory.CREW_ROOM,
		RoomCategory.MAINTENANCE_ROOM,
		RoomCategory.EMERGENCY_ROOM,
		RoomCategory.RESEARCH_ROOM,
		RoomCategory.LUXURY_ROOM,
		RoomCategory.SPECIAL_ROOM
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

## Returns the starting order. Converts the "rooms" value from enums to room_data dicts.
static func get_starting_order() -> Dictionary:
	var new_order: Dictionary = starting_order.duplicate(true)
	var room_data_array = []
	for room_enum in new_order.rooms:
		room_data_array.append(RoomData.room_data[room_enum])

	room_data_array.sort_custom(room_sort)

	new_order.erase("rooms")
	new_order["selected_rooms"] = room_data_array
	return new_order


## Returns a random order from the orders dict, converting the "rooms" value from enums to room_data dicts.
## If the order contains a "choose_from" field with value n, n + <extra_options> random rooms are selected from the list.
static func get_random_order(extra_options: int = 0) -> Dictionary:
	var shuffled_keys = orders.keys().duplicate(true)
	shuffled_keys.shuffle()
	var new_order: Dictionary = orders[shuffled_keys[0]].duplicate(true)
	order_history.append(shuffled_keys[0])

	var room_data_array = []

	if "room_categories" in new_order:
		# if order has categories instead of specific rooms
		for room_data_dict in RoomData.room_data.values():
			if room_data_dict["room_category"] in new_order.room_categories:
				room_data_array.append(room_data_dict)
	else:
		for room_enum in new_order.rooms:
			room_data_array.append(RoomData.room_data[room_enum])

	if "choose_from" in new_order:
		room_data_array.shuffle()
		room_data_array = room_data_array.slice(0, new_order["choose_from"] + extra_options)

	room_data_array.sort_custom(room_sort)

	new_order.erase("rooms")
	new_order.erase("room_categories")
	new_order["selected_rooms"] = room_data_array
	return new_order


static func get_specific_order(order_enum: OrderData.Order) -> Dictionary:
	var new_order: Dictionary = special_orders[order_enum].duplicate(true)
	order_history.append(order_enum)

	var room_data_array = []

	if "room_categories" in new_order:
		# if order has categories instead of specific rooms
		for room_data_dict in RoomData.room_data.values():
			if room_data_dict["room_category"] in new_order.room_categories:
				room_data_array.append(room_data_dict)
	else:
		for room_enum in new_order.rooms:
			room_data_array.append(RoomData.room_data[room_enum])

	if "choose_from" in new_order:
		room_data_array.shuffle()
		room_data_array = room_data_array.slice(0, new_order["choose_from"])

	room_data_array.sort_custom(room_sort)

	new_order.erase("rooms")
	new_order.erase("room_categories")
	new_order["selected_rooms"] = room_data_array
	return new_order

static func get_order_for_next_turn(active_data_rooms: int) -> Dictionary:
	if GlobalVariables.turn == 3:
		return get_specific_order(Order.CARGO_BAY_ORDER)
	elif GlobalVariables.turn % 5 == 0:
		return get_specific_order(Order.RESEARCH_ROOM_ORDER)
	return get_random_order(active_data_rooms)
