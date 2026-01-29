class_name CrewMember
extends Control

var crewmember_name: String
var crew_quarters: Room # the CrewMember's assigned Crew Quarters
var assigned_to: Room # the CrewMember's current location

var hovering: bool = false
var picked: bool = false

@export var name_label: RichTextLabel

## NOTE: Currently, room.gd is responsible for changing the <picked> variable, and moving the crew member between rooms.

func _process(_delta: float) -> void:
	if picked:
		var global_mouse_pos = get_global_mouse_position()
		global_position = global_mouse_pos


func init_crew_member(p_name: String, p_crew_quarters: Room, p_assigned_to: Room):
	crewmember_name = p_name
	crew_quarters = p_crew_quarters
	assigned_to = p_assigned_to

	name_label.text = crewmember_name


func create_random_name(already_used: Array[String]) -> String:
	var random_name = "C"
	while true:
		for i in range(2):
			random_name += str(randi_range(0, 9))
		if random_name not in already_used:
			break
	return random_name

## Return an Array of Rooms this CrewMember can access from their current location.
## Does not include their own location.
func get_accessible_rooms() -> Array[Room]:
	var accessible_rooms = RoomConnections.get_all_rooms(assigned_to, -1, true)
	return accessible_rooms


func _on_mouse_entered() -> void:
	hovering = true


func _on_mouse_exited() -> void:
	hovering = false
