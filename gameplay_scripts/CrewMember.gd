class_name CrewMember
extends Node

var crewmember_name: String
var crew_quarters: Room # the CrewMember's assigned Crew Quarters
var assigned_to: Room # the CrewMember's current location


func _ready() -> void:
	pass


## Return an Array of Rooms this CrewMember can access from their current location.
## Does not include their own location.
func get_accessible_rooms() -> Array[Room]:
	var accessible_rooms = RoomConnections.get_all_rooms(assigned_to, -1, true)
	return accessible_rooms
