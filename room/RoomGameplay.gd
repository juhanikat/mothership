extends Node
class_name RoomGameplay


var _data: Dictionary[String, Variant]
@onready var parent_room: Room
@onready var main: Main

var RoomType = RoomData.RoomType
var parent_room_type: RoomData.RoomType

var powered: bool = false
var activated: bool = false
var power_usage: int


# FOR POWER SUPPLIERS
var power_supply = {}
var supplies_to: Array[Room] = []

# FOR CREW SUPPLIERS
var crew_supply: int = 0



## RoomGameplay is created and added as a child to a Room node (in room.gd).
func _ready() -> void:
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

	power_usage = _data["power_usage"]
	if power_usage == 0:
		# Rooms that have 0 power usage are always powered.
		powered = true
		print("Room powered by default when spawning.")


## Called when a deactivated room is middle-clicked. Calls lots of other functions depending on room type.
## Returns true if the room has been activated, and false otherwise.
## NOTE: Rooms with a power usage of 0 have already been powered before this function!
func activate_room() -> bool:
	var power_supplier = _find_power_supplier()
	if power_usage != 0 and not power_supplier:
		return false
	activated = _try_to_activate()
	if activated:
		parent_room.texture_polygon.color.a += 0.5
		if power_supplier:
			power_supplier.gameplay.power_supply.capacity -= power_usage
			power_supplier.gameplay.supplies_to.append(parent_room)
			power_supplier.room_info.update_power_supply_label(power_supplier.gameplay.power_supply)
			powered = true
			print("Room powered.")
		return true
	return false


## Called when an activated room is middle-clicked. Calls lots of other functions depending on room type.
## Returns true if the room has been deactivated, and false otherwise. (Can this even fail?)
func deactivate_room() -> bool:
	if power_usage != 0 and powered:
		for power_supplier: Room in get_tree().get_nodes_in_group("PowerSupply"):
			if parent_room in power_supplier.gameplay.supplies_to:
				power_supplier.gameplay.power_supply.capacity += power_usage
				power_supplier.gameplay.supplies_to.erase(parent_room)
				power_supplier.room_info.update_power_supply_label(power_supplier.gameplay.power_supply)
		powered = false
		print("Power removed.")

	match parent_room_type:
		RoomType.CREW_QUARTERS:
			GlobalSignals.crew_removed.emit(crew_supply)
		RoomType.GARDEN:
			GlobalSignals.crew_quarters_limit_lowered.emit(_data["crew_quarters_limit_increase"])

	activated = false
	parent_room.texture_polygon.color.a -= 0.5
	return true


## Returns true if the room has been activated, or false otherwise.
func _try_to_activate() -> bool:
	match parent_room_type:
		RoomType.CREW_QUARTERS:
			var canteen_distance = RoomConnections.find_nearest_room_type(parent_room, RoomData.RoomType.CANTEEN, [RoomData.RoomCategory.CREW_ROOM])
			if len(canteen_distance) == 0 or canteen_distance[0].gameplay.powered == false:
				print("Cannot activate Crew Quarters: No powered canteen can be reached through Crew Rooms.")
				return false
			var all_crew_quarters = get_tree().get_nodes_in_group("CrewQuarters")
			var activated_crew_quarters = all_crew_quarters.filter(func(crew_quarter): return crew_quarter.gameplay.activated)
			if len(activated_crew_quarters) >= main.crew_quarters_limit:
				print("Cannot activate Crew Quarters: Crew Quarters limit has been reached.")
				return false
			GlobalSignals.crew_added.emit(crew_supply)

		RoomType.GARDEN:
			GlobalSignals.crew_quarters_limit_raised.emit(_data["crew_quarters_limit_increase"])
	return true


## Returns the nearest power supplier with sufficient capacity and range if one was found,
## and null otherwise.
func _find_power_supplier():
	var not_in_range = true
	var power_suppliers = get_tree().get_nodes_in_group("PowerSupply")
	for power_supplier: Room in power_suppliers:
		var power_supplier_reach = RoomConnections.get_nearby_rooms(power_supplier, power_supplier.gameplay.power_supply.range)
		if parent_room in power_supplier_reach:
			not_in_range = false
			if power_supplier.gameplay.power_supply.capacity >= power_usage:
				return power_supplier
	if not_in_range:
		print("Cannot power room: No suppliers in range.")
	else:
		print("Cannot power room: Suppliers in rage do not have enough capacity.")
	return null
