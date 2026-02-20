extends Script
class_name OrderFunctions

## Holds functions related to the selection of new rooms and events.
## Actual HUD for the room selection is elsewhere.
## Also check out OrderData.gd.
static var basic_orders = OrderData.basic_orders.duplicate(true)
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


## Returns a normal order (which are upgraded if there are active data analysis rooms).
static func _get_normal_order(active_data_rooms: int = 0) -> Dictionary:
	var orders_enums = basic_orders.keys().duplicate(true)
	if active_data_rooms == 0:
		return _get_specific_order(orders_enums[0], active_data_rooms)
	elif active_data_rooms == 1:
		return _get_specific_order(orders_enums[1], active_data_rooms)
	else:
		return _get_specific_order(orders_enums[2], active_data_rooms)


## Returns an order's data, converting the "rooms" value from enums to room_data dicts.
static func _get_specific_order(order_enum: OrderData.Order, active_data_rooms: int) -> Dictionary:
	var new_order: Dictionary = {}
	if order_enum in basic_orders:
		new_order = basic_orders[order_enum].duplicate(true)
	else:
		new_order = special_orders[order_enum].duplicate(true)
	order_history.append(order_enum)

	var room_data_array = []

	if "room_categories_array" in new_order:
		# if order has categories instead of specific rooms, this is the only case where active data rooms have an effect
		for room_data_dict in RoomData.room_data.values():
			if room_data_dict["room_category"] in new_order.room_categories_array:
				room_data_array.append(room_data_dict)
		if "choose_from" in new_order:
			room_data_array.shuffle()
			room_data_array = room_data_array.slice(0, new_order["choose_from"] + active_data_rooms)

	if "room_categories_dict" in new_order:
		# if the category selection is a dict, it contains an exact amount of rooms chosen for each category
		for category in new_order["room_categories_dict"]:
			var amount = new_order["room_categories_dict"][category]
			var rooms = RoomData.room_data.values().filter(func(room_data): return room_data["room_category"] == category)
			rooms.shuffle()
			for room_data in rooms.slice(0, amount):
				room_data_array.append(room_data)

	if "rooms" in new_order:
		for room_enum in new_order.rooms:
			room_data_array.append(RoomData.room_data[room_enum])

	room_data_array.sort_custom(room_sort)

	new_order.erase("rooms")
	new_order.erase("room_categories")
	new_order["selected_rooms"] = room_data_array
	return new_order


static func get_order_for_next_turn(active_data_rooms: int) -> Dictionary:
	if GlobalVariables.turn == 1:
		return _get_specific_order(Order.STARTING_ORDER, active_data_rooms)
	if GlobalVariables.turn == 3:
		return _get_specific_order(Order.CARGO_BAY_ORDER, active_data_rooms)
	elif GlobalVariables.turn % 5 == 0:
		return _get_specific_order(Order.RESEARCH_ROOM_ORDER, active_data_rooms)
	return _get_normal_order(active_data_rooms)
