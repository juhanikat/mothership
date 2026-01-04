extends Node
class_name CaptainFunctions

## Holds functions related to the selection of new rooms etc.
## Actual HUD for the room selection is elsewhere.
## Also check out CaptainData.gd.
static var starting_orders = CaptainData.starting_orders.duplicate(true)
static var orders = CaptainData.orders.duplicate(true)


# NOTE: The orders appended to these Arrays are modified from the original orders!
static var starting_order_history: Array[Dictionary] = []
static var order_history: Array[CaptainData.Order] = []



## Returns the next starting order in the starting_orders list, removing it from that list,
## and converting the "rooms" value from enums to room_data dicts.
static func next_starting_order() -> Dictionary:
	var new_order: Dictionary = starting_orders.pop_front().duplicate(true)
	var room_data_array = []
	for room_enum in new_order.rooms:
		room_data_array.append(RoomData.room_data[room_enum])

	new_order.erase("rooms")
	new_order["selected_rooms"] = room_data_array
	starting_order_history.append(new_order)
	return new_order


## Returns a random order from the orders dict, converting the "rooms" value from enums to room_data dicts.
## If the order contains a "choose_from" field with value n, n random rooms are selected from the list.
static func random_order() -> Dictionary:
	var shuffled_keys = orders.keys().duplicate(true)
	shuffled_keys.shuffle()
	var new_order: Dictionary = orders[shuffled_keys[0]].duplicate(true)

	var room_data_array = []
	for room_enum in new_order.rooms:
		room_data_array.append(RoomData.room_data[room_enum])

	if "choose_from" in new_order:
		room_data_array.shuffle()
		room_data_array = room_data_array.slice(0, new_order["choose_from"])

	new_order.erase("rooms")
	new_order["selected_rooms"] = room_data_array
	starting_order_history.append(new_order)
	return new_order
