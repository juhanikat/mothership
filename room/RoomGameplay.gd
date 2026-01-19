extends Node
class_name RoomGameplay


var _data: Dictionary[String, Variant]
@onready var parent_room: Room
@onready var main: Main = get_tree().root.get_node("Main")
@onready var hud: Hud = main.get_node("HUD")


var RoomType = RoomData.RoomType
var parent_room_type: RoomData.RoomType

var activated: bool = false
var always_activated: bool = false # Room is activated automatically once connected, and cannot be deactivated
var always_deactivated: bool = false
var cannot_be_deactivated: bool = false # used by e.g. Cargo Bay and Crew Quarters
var power_usage: int

# FOR CARGO BAY
var order_in_progress: bool = false
var delivery_in_progress: bool = false
var turns_until_delivery: int = -1
var current_delivery: Dictionary # Contains type, turns_left, and made_by: Room

# FOR FUEL STORAGE
var fuel_remaining: int = 0

# FOR POWER SUPPLIERS
var power_supply = {}
var supplies_to: Array[Room] = []

# FOR CREW SUPPLIERS
var crew_supply: int = 0



## RoomGameplay is created and added as a child to a Room node (in room.gd).
func _ready() -> void:
	add_to_group("RoomGameplay")
	parent_room = get_parent()
	parent_room_type = parent_room.room_type
	main = get_tree().root.get_node("Main")


func init_gameplay_features(data: Dictionary) -> void:
	_data = data

	if "power_supply" in _data.keys():
		power_supply = _data["power_supply"].duplicate(true)
		parent_room.add_to_group("PowerSupply")

	if "crew_supply" in _data.keys():
		crew_supply = _data["crew_supply"]
		parent_room.add_to_group("CrewSupply")

	if parent_room_type == RoomType.CREW_QUARTERS:
		parent_room.add_to_group("CrewQuarters")
	elif parent_room_type == RoomType.FUEL_STORAGE:
		fuel_remaining = _data["fuel_amount"]
		parent_room.add_to_group("FuelStorage")
	elif parent_room_type == RoomType.LAVATORY:
		parent_room.add_to_group("Lavatory")
	elif parent_room_type == RoomType.WPP:
		parent_room.add_to_group("WPP")
	elif parent_room_type == RoomType.DATA_ANALYSIS:
		parent_room.add_to_group("DataAnalysis")


	power_usage = _data["power_usage"]

	always_activated = _data.get("always_activated", false)
	always_deactivated = _data.get("always_deactivated", false)
	cannot_be_deactivated = _data.get("cannot_be_deactivated", false)

	GlobalSignals.room_connected.connect(_on_room_connected)
	GlobalSignals.cargo_bay_order_made.connect(_on_cargo_bay_order_made)


## Called when a deactivated room is middle-clicked. Calls lots of other functions depending on room type.
## Returns true if the room has been activated, and false otherwise.
## NOTE: Rooms with "always_activated" set to true have already been activated before this function!
func activate_room() -> bool:
	if always_deactivated:
		GlobalNotice.display("Cannot activate room: It is set to be always deactivated.", "warning")
		return false

	var sufficient_power_supplier
	if power_usage != 0:
		sufficient_power_supplier = _find_power_supplier()
		if not sufficient_power_supplier:
			return false

	activated = _try_to_activate()
	if activated:
		parent_room.texture_polygon.color.a += 0.5
		if power_usage != 0:
			sufficient_power_supplier.gameplay.power_supply.capacity -= power_usage
			sufficient_power_supplier.gameplay.supplies_to.append(parent_room)
			sufficient_power_supplier.room_info.update_power_supply_label(sufficient_power_supplier.gameplay.power_supply)
		GlobalNotice.display("Room activated.")
		return true
	return false


## Called when an activated room is middle-clicked. Calls lots of other functions depending on room type.
## Returns true if the room has been deactivated, and false otherwise.
func deactivate_room() -> bool:
	if not activated:
		push_error("Tried to deactivate room that was not active, this should never happen!")
		return false

	if always_activated:
		GlobalNotice.display("Cannot deactivate room: It is set to be always active.", "warning")
		return false
	if cannot_be_deactivated:
		GlobalNotice.display("Cannot deactivate room: 'cannot_be_deactivated' is set to true.", "warning")
		return false

	if power_usage != 0:
		for power_supplier: Room in get_tree().get_nodes_in_group("PowerSupply"):
			if parent_room in power_supplier.gameplay.supplies_to:
				power_supplier.gameplay.power_supply.capacity += power_usage
				power_supplier.gameplay.supplies_to.erase(parent_room)
				power_supplier.room_info.update_power_supply_label(power_supplier.gameplay.power_supply)

	match parent_room_type:
		RoomType.POWER_PLANT:
			if len(supplies_to) > 0:
				GlobalNotice.display("Cannot deactivate Power Plant: It is supplying power to one or more rooms.", "warning")
				return false
		RoomType.CREW_QUARTERS:
			GlobalSignals.crew_removed.emit(crew_supply)
		RoomType.WPP:
			var activated_wpps = []
			for wpp: Room in get_tree().get_nodes_in_group("WPP"):
				if wpp.gameplay.activated:
					activated_wpps.append(wpp)
			if len(activated_wpps) == 1:
				# if this is the only activated WPP, it cannot be deactivated if any Lavatory is currently activated
				for lavatory: Room in get_tree().get_nodes_in_group("Lavatory"):
					if lavatory.gameplay.activated:
						GlobalNotice.display("Cannot deactivate Waste Processing Plant: There are activated Lavatories that depend on it.", "warning")
						return false
		RoomType.GARDEN:
			GlobalSignals.crew_quarters_limit_lowered.emit(_data["crew_quarters_limit_increase"])
		RoomType.CARGO_BAY:
			if delivery_in_progress:
				GlobalNotice.display("Cannot deactivate Cargo Bay: A delivery is in progress.", "warning")
				return false

	activated = false
	parent_room.texture_polygon.color.a -= 0.5
	GlobalNotice.display("Room deactivated.")
	return true


## Find any Fuel Storage (nearest first) that has fuel remaining and is in range (3 rooms) of this room.
func find_sufficient_fuel_storage():
	var all_fuel_storage_data = RoomConnections.find_all_room_types(parent_room, RoomData.RoomType.FUEL_STORAGE)
	for fuel_storage_data in all_fuel_storage_data:
		if fuel_storage_data.distance > 3 or fuel_storage_data.room.gameplay.fuel_remaining == 0:
			continue
		return fuel_storage_data.room
	return null


## Returns true if the room has been activated, or false otherwise.
## Checks all rules other than the availability of power, which is done before this in activate_room().
func _try_to_activate() -> bool:
	match parent_room_type:
		RoomType.CREW_QUARTERS:
			var nearest_canteen_data = RoomConnections.find_nearest_room_type(parent_room, RoomData.RoomType.CANTEEN, [RoomData.RoomCategory.CREW_ROOM])
			if len(nearest_canteen_data) == 0 or nearest_canteen_data[0].gameplay.activated == false:
				GlobalNotice.display("Cannot activate Crew Quarters: No activated canteen can be reached through Crew Rooms.", "warning")
				return false
			var all_crew_quarters = get_tree().get_nodes_in_group("CrewQuarters")
			var activated_crew_quarters = all_crew_quarters.filter(func(crew_quarter): return crew_quarter.gameplay.activated)
			if len(activated_crew_quarters) >= main.crew_quarters_limit:
				GlobalNotice.display("Cannot activate Crew Quarters: Crew Quarters limit has been reached.", "warning")
				return false
			GlobalSignals.crew_added.emit(crew_supply)
		RoomType.LAVATORY:
			var nearest_wpp_data = RoomConnections.find_nearest_room_type(parent_room, RoomData.RoomType.WPP)
			if len(nearest_wpp_data) == 0 or nearest_wpp_data[0].gameplay.activated == false:
				GlobalNotice.display("Cannot activate Lavatory: No activated Waste Processing Plant on the station.", "warning")
				return false
		RoomType.POWER_PLANT:
			var fuel_storage = find_sufficient_fuel_storage()
			if not fuel_storage:
				GlobalNotice.display("Cannot activate Power Plant: No Fuel Storages with fuel remaining are in range.", "warning")
				return false
		RoomType.GARDEN:
			GlobalSignals.crew_quarters_limit_raised.emit(_data["crew_quarters_limit_increase"])
		RoomType.CARGO_BAY:
			if not order_in_progress and not delivery_in_progress:
				order_in_progress = true
				main.new_cargo_order(parent_room)
				# cargo bay will be activated again once order is made
				return false

	return true


## Returns the nearest ACTIVATED power supplier with sufficient capacity and range if one was found,
## and null otherwise.
func _find_power_supplier():
	var not_in_range = true
	var power_suppliers = get_tree().get_nodes_in_group("PowerSupply")
	power_suppliers = power_suppliers.filter(func(supplier): return supplier.gameplay.activated)
	for power_supplier: Room in power_suppliers:
		var power_supplier_reach = RoomConnections.get_nearby_rooms(power_supplier, power_supplier.gameplay.power_supply.range)
		if parent_room in power_supplier_reach:
			not_in_range = false
			if power_supplier.gameplay.power_supply.capacity >= power_usage:
				return power_supplier
	if not_in_range:
		GlobalNotice.display("Cannot power room: No activated suppliers in range.", "warning")
	else:
		GlobalNotice.display("Cannot power room: Activated suppliers in range do not have enough capacity.", "warning")
	return null

## Called by main when the turn is advanced. Does not listen to a signal because things need to be done in order,
## which might be hard when multiple nodes listen to the same signal.
func next_turn() -> void:
	if parent_room_type == RoomType.POWER_PLANT and activated:
		var fuel_storage = find_sufficient_fuel_storage()
		if not fuel_storage:
			GlobalNotice.display("Power Plant does not have any accessible fuel!", "warning")
			for room in supplies_to:
				room.gameplay.deactivate_room()
			supplies_to.clear()
			deactivate_room()
		else:
			fuel_storage.gameplay.fuel_remaining -= 1
			fuel_storage.room_info.update_fuel_remaining_label(fuel_storage.gameplay.fuel_remaining)

	if delivery_in_progress:
		current_delivery.turns_left -= 1
		GlobalSignals.delivery_status_changed.emit(current_delivery)
		if current_delivery.turns_left == 0:
			delivery_in_progress = false
			cannot_be_deactivated = false
			if current_delivery.type == "Fuel":
				var all_fuel_storages = get_tree().get_nodes_in_group("FuelStorage")
				if not all_fuel_storages:
					GlobalNotice.display("Could not deliver Fuel: There aren't any Fuel Storages on the station.")
					return
				else:
					var random_fuel_storage = all_fuel_storages.pick_random()
					random_fuel_storage.gameplay.fuel_remaining += 5
					random_fuel_storage.room_info.update_fuel_remaining_label(random_fuel_storage.gameplay.fuel_remaining)
					GlobalNotice.display("Fuel delivered.")
			elif current_delivery.type == "Rations":
				GlobalNotice.display("Rations delivered.")
			else:
				push_error("Invalid delivery type!!")
			deactivate_room()
			return




## Things that need to be done as soon as the room is connected are here.
func _on_room_connected(connector1: Connector, connector2: Connector) -> void:
	if connector1.get_parent_room() == parent_room or connector2.get_parent_room() == parent_room:
		if always_activated:
			var can_be_activated = activate_room()
			if not can_be_activated:
				push_error("Room with always_activated set to true did not have enough power to activate, it should not be able to be placed!!!! fix!!!")
			GlobalNotice.display("Room activated automatically!")


func _on_cargo_bay_order_made(delivery: Dictionary) -> void:
	if delivery.made_by == parent_room:
		cannot_be_deactivated = true
		order_in_progress = false
		delivery_in_progress = true
		current_delivery = delivery
		activate_room()
