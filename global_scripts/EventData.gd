extends Node
## This node is Autoloaded since event_data cannot be used in other scripts otherwise
## (because it is not a const, and it can't be a const because the _data dictionaries have functions in them).

const RoomCategory = RoomData.RoomCategory

enum EVENTS {FIRE_1, IMPOSTERS_1, SHOCK_1, BUILD_RESEARCH}
enum CHOICES {}

var _build_research_data = {
	"title": "Build more Research Rooms",
	"description": "",
	"probability": 1,
	"can_appear_func": func(scene_tree: SceneTree): return len(scene_tree.get_nodes_in_group(str(RoomCategory.RESEARCH_ROOM))) < GlobalVariables.turn / 3.0
}

var _shock_1_data = {
	"title": "A wave sweeps over the station",
	"description": "The force of the anomaly is not enough to cause injury, but it is enough to wake you up. The entire station has apparently experienced periodic electromagnetic pulses for the last few hours, with the latest one being the strongest one yet.

	\"We're still investigating, but it doesn't seem to be originating from any machinery. Nothing's damaged yet either, but that might change soon.\"
	",
	"probability": 1,
	"can_appear_func": func(_scene_tree: SceneTree): return true
}

# this has to be last
var event_data = {
	EVENTS.BUILD_RESEARCH: _build_research_data,
	EVENTS.SHOCK_1: _shock_1_data,
}
