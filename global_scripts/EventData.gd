extends Node
## This node is Autoloaded since event_data cannot be used in other scripts otherwise
## (because it is not a const, and it can't be a const because the _data dictionaries have functions in them).

const RoomType = RoomData.RoomType
const RoomCategory = RoomData.RoomCategory

enum EVENTS {FIRE_1, IMPOSTERS_1, SHOCK_1, BUILD_RESEARCH, POWER_PLANT_MAINTENANCE_1, POWER_PLANT_MAINTENANCE_2_SUCCESS,
POWER_PLANT_MAINTENANCE_2_FAILURE}

enum CHOICES {PPM_1_A, PPM_1_B}

var _build_research_data = {
	"title": "Build more Research Rooms",
	"description": "",
	"probability": 1,
	"can_appear_func": func(scene_tree: SceneTree): return len(scene_tree.get_nodes_in_group(str(RoomCategory.RESEARCH_ROOM))) < GlobalVariables.turn / 3.0
}

var _shock_1_data = {
	"title": "A wave sweeps over the station",
	"description": "The force of the anomaly is not enough to cause injury, but it is enough to wake you up. The entire station has apparently experienced periodic electromagnetic pulses for the last few hours, with this latest one being the strongest yet.

	\"We're still investigating, but it doesn't seem to be originating from any machinery. Nothing's damaged yet either, but that might change soon.\"
	",
	"probability": 1,
	"can_appear_func": func(_scene_tree: SceneTree): return true
}

var _power_plant_maintenance_1_data = {
	"title": "Power Plant maintenance",
	"description": "One of the Power Plants on your station has been active for quite a long time. If able, consider powering it down so your crew can make repairs and overhauls.
	",
	"probability": 1,
	"choices": [{"text": "Deactivate the Power Plant for one turn.", "value": CHOICES.PPM_1_A}, {"text": "Ignore.", "value": CHOICES.PPM_1_B}],
	"can_appear_func": func(scene_tree: SceneTree): return len(scene_tree.get_nodes_in_group(str(RoomType.POWER_PLANT)) \
					.filter(func(room: Room): return room.gameplay.activated)) > 0
}

var _power_plant_maintenance_2_success_data = {
	"title": "Power Plant deactivated",
	"description": "The Power Plant has been deactivated.
	",
	"probability": 0,
	"can_appear_func": func(_scene_tree: SceneTree): return false
}

var _power_plant_maintenance_2_failure_data = {
	"title": "Power Plant cannot be deactivated",
	"description": "The Power Plant could not be deactivated! It is probably supplying power to a room that is always active.
	",
	"probability": 0,
	"can_appear_func": func(_scene_tree: SceneTree): return false
}

# this has to be last
var event_data = {
	EVENTS.BUILD_RESEARCH: _build_research_data,
	EVENTS.SHOCK_1: _shock_1_data,
	EVENTS.POWER_PLANT_MAINTENANCE_1: _power_plant_maintenance_1_data,
	EVENTS.POWER_PLANT_MAINTENANCE_2_SUCCESS: _power_plant_maintenance_2_success_data,
	EVENTS.POWER_PLANT_MAINTENANCE_2_FAILURE: _power_plant_maintenance_2_failure_data,
}
