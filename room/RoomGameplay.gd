extends Node
class_name RoomGameplay


var _data: Dictionary[String, Variant]
@onready var parent_room: Room

var powered: bool = false


# FOR POWER SUPPLIERS
var power_supply = {}
var supplies_to: Array[Room] = []


## RoomGameplay is created and added as a child to a Room node (in room.gd).
func _ready() -> void:
	parent_room = get_parent()


func init_gameplay_features(data: Dictionary) -> void:
	_data = data

	if "power_supply" in _data.keys():
		power_supply = _data["power_supply"].duplicate(true)
		parent_room.add_to_group("PowerSupply")

	if _data["power_usage"] == 0:
		# Rooms that have 0 power usage are always powered.
		powered = true
		parent_room.texture_polygon.color.a += 0.5


func toggle_power() -> void:
	var power_usage: int = _data["power_usage"]
	if power_usage == 0:
		# Rooms that have 0 power usage are always powered.
		print("Cannot power room: it has power usage of 0.")
		return


	var not_in_range = true
	if powered:
		for power_supplier: Room in get_tree().get_nodes_in_group("PowerSupply"):
			if parent_room in power_supplier.gameplay.supplies_to:
				power_supplier.gameplay.power_supply.capacity += power_usage
				power_supplier.gameplay.supplies_to.erase(parent_room)
				power_supplier.room_info.update_power_supply_label(power_supplier.gameplay.power_supply)
		powered = false
		parent_room.texture_polygon.color.a -= 0.5
	else:
		var power_suppliers = get_tree().get_nodes_in_group("PowerSupply")
		for power_supplier: Room in power_suppliers:
			var power_supplier_reach = RoomConnections.get_nearby_rooms(power_supplier, power_supplier.gameplay.power_supply.range)
			if parent_room in power_supplier_reach:
				not_in_range = false
				if power_supplier.gameplay.power_supply.capacity >= power_usage:
					power_supplier.gameplay.power_supply.capacity -= power_usage
					power_supplier.gameplay.supplies_to.append(parent_room)
					power_supplier.room_info.update_power_supply_label(power_supplier.gameplay.power_supply)
					powered = true
					parent_room.texture_polygon.color.a += 0.5
					print("Room powered.")
					return
		if not_in_range:
			print("Cannot power room: No suppliers in range.")
		else:
			print("Cannot power room: Suppliers in rage do not have enough capacity.")
