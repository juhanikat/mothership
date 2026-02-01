class_name RoomData
extends Node


enum RoomShape {LShape, TShape, SmallSquareShape, BigSquareShape, LongHallwayShape}
enum RoomType {
	COMMAND_ROOM, POWER_PLANT, ENGINE_ROOM, CARGO_BAY, CREW_QUARTERS,
	CANTEEN, LAVATORY, RATION_STORAGE, WPP, FUEL_STORAGE, GARDEN, ROBOTICS, WEAPONS_RESEARCH, DATA_ANALYSIS, ARMORY, CABLE_DUCT, PLACEHOLDER_ROOM
}
enum RoomCategory {CREW_ROOM, MAINTENANCE_ROOM, RESEARCH_ROOM, EMERGENCY_ROOM, LUXURY_ROOM, SPECIAL_ROOM}


const room_colors = {
	RoomCategory.CREW_ROOM: Color(0.212, 0.561, 0.812),
	RoomCategory.MAINTENANCE_ROOM: Color(0.957, 0.588, 0.098),
	RoomCategory.RESEARCH_ROOM: Color(0.678, 0.0, 0.68),
	RoomCategory.EMERGENCY_ROOM: Color(0.681, 0.257, 0.219),
	RoomCategory.LUXURY_ROOM: Color(0.394, 0.834, 0.113),
	RoomCategory.SPECIAL_ROOM: Color(0.925, 0.925, 0.925)
	}


## Maps the shape of a room to the top left corner of the room the info should be.
const room_info_pos = {
	RoomShape.LShape: Vector2(-64, -64),
	RoomShape.TShape: Vector2(-64, -64),
	RoomShape.SmallSquareShape: Vector2(-32, -32),
	RoomShape.BigSquareShape: Vector2(-64, -64),
	RoomShape.LongHallwayShape: Vector2(-192, -32)
}


## Maps a RoomShape to an Array containing the locations of its connectors.
## NOTE: Add some offset to these so the rooms are not adjacent when snapped,
## otherwise room area detection does not work!
const room_connectors = {
	RoomShape.LShape: [Vector2(0, -72), Vector2(72, -32), Vector2(-32, 72), Vector2(-72, 0)],
	RoomShape.TShape: [Vector2(0, -72), Vector2(104, 32), Vector2(-104, 32)],
	RoomShape.SmallSquareShape: [Vector2(0, -40),Vector2(40, 0), Vector2(0, 40), Vector2(-40, 0)],
	RoomShape.BigSquareShape: [Vector2(0, -72), Vector2(72, 0), Vector2(0, 72), Vector2(-72, 0)],
	RoomShape.LongHallwayShape: [Vector2(-200, 0), Vector2(200, 0)]
}


## NOTE: Use this dict in other scripts.
const room_data = {
	RoomType.COMMAND_ROOM: _command_room_data,
	RoomType.POWER_PLANT: _power_plant_data,
	RoomType.CARGO_BAY: _cargo_bay_data,
	RoomType.CREW_QUARTERS: _crew_quarters_data,
	RoomType.CANTEEN: _canteen_data,
	RoomType.LAVATORY: _lavatory_data,
	RoomType.RATION_STORAGE: _ration_storage_data,
	RoomType.WPP: _wpp_data,
	RoomType.FUEL_STORAGE: _fuel_storage_data,
	RoomType.GARDEN: _garden_data,
	RoomType.ROBOTICS: _robotics_data,
	RoomType.WEAPONS_RESEARCH: _weapons_research_data,
	RoomType.DATA_ANALYSIS: _data_analysis_data,
	RoomType.CABLE_DUCT: _cable_duct_data,
	RoomType.ARMORY: _armory_data,
	RoomType.PLACEHOLDER_ROOM: _placeholder_room_data
}


## TODO: Use classes instead of dicts here to get autocomplete?

## SPECIAL ROOMS


const _command_room_data: Dictionary[String, Variant] = {
	"room_name": "Command Room",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "",
	"room_category": RoomCategory.SPECIAL_ROOM,
	"power_usage": 0
}

const _power_plant_data: Dictionary[String, Variant] = {
	"room_name": "Power Plant",
	"room_shape": RoomShape.LShape,
	"room_desc": "Provides power for nearby rooms. Needs a Fuel Storage within 3 rooms to activate. When activated, uses 1 Fuel each turn.",
	"room_category": RoomCategory.SPECIAL_ROOM,
	"power_usage": 0,
	"power_supply": {"capacity": 10, "range": 5}
}

const _cargo_bay_data: Dictionary[String, Variant] = {
	"room_name": "Cargo Bay",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "Allows importing resources such as fuel. Each delivery takes 3 turns to complete, and the room is locked in a powered state during that time.",
	"room_category": RoomCategory.SPECIAL_ROOM,
	"power_usage": 1
}


## CREW ROOMS


const _crew_quarters_data: Dictionary[String, Variant] = {
	"room_name": "Crew Quarters",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "Must be connected to a Canteen through Crew Rooms to activate.",
	"room_category": RoomCategory.CREW_ROOM,
	"power_usage": 1,
	"crew_amount": 4,
	"cannot_be_deactivated": true
}

const _canteen_data: Dictionary[String, Variant] = {
	"room_name": "Canteen",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "Must be placed adjacent to a Crew Room. Needs a Ration Storage next to it to activate. When activated, uses 1 Ration each turn.",
	"room_category": RoomCategory.CREW_ROOM,
	"power_usage": 1
}

const _lavatory_data: Dictionary[String, Variant] = {
	"room_name": "Lavatory",
	"room_shape": RoomShape.TShape,
	"room_desc": "Must be placed adjacent to a Crew Room. There must be a Waste Processing Plant on the station to activate.",
	"room_category": RoomCategory.CREW_ROOM,
	"power_usage": 1
}

const _ration_storage_data: Dictionary[String, Variant] = {
	"room_name": "Ration Storage",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "Must be placed next to a Canteen.",
	"room_category": RoomCategory.CREW_ROOM,
	"always_activated": true,
	"power_usage": 0,
	"rations_amount": 10
}


## MAINTENANCE ROOMS

const _wpp_data: Dictionary[String, Variant] = {
	"room_name": "Waste Processing Plant",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "Must be on the station to activate Lavatories.
					Adds one fuel to the nearest Fuel Storage for every two lavatories
					that are activated at the end of the turn.",
	"room_category": RoomCategory.MAINTENANCE_ROOM,
	"power_usage": 2
}

const _cable_duct_data: Dictionary[String, Variant] = {
	"room_name": "Cable Duct",
	"room_shape": RoomShape.LongHallwayShape,
	"room_desc": "",
	"room_category": RoomCategory.MAINTENANCE_ROOM,
	"power_usage": 0,
	"accessible_by_crew": false
}

const _fuel_storage_data: Dictionary[String, Variant] = {
	"room_name": "Fuel Storage",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "",
	"room_category": RoomCategory.MAINTENANCE_ROOM,
	"power_usage": 0,
	"always_activated": true,
	"fuel_amount": 5
}

const _placeholder_room_data: Dictionary[String, Variant] = {
	"room_name": "Placeholder Room",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "A placeholder room can be replaced by another room of the same size.",
	"room_category": RoomCategory.MAINTENANCE_ROOM,
	"power_usage": 0,
	"always_deactivated": true
}


## LUXURY ROOMS


const _garden_data: Dictionary[String, Variant] = {
	"room_name": "Garden",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "Raises your crew quarter limit by 2.",
	"room_category": RoomCategory.LUXURY_ROOM,
	"power_usage": 0,
	"crew_quarters_limit_increase": 2,
	"always_activated": true
}


## RESEARCH ROOMS


const _robotics_data: Dictionary[String, Variant] = {
	"room_name": "Robotics",
	"room_shape": RoomShape.LShape,
	"room_desc": "",
	"room_category": RoomCategory.RESEARCH_ROOM,
	"power_usage": 1
}

const _weapons_research_data: Dictionary[String, Variant] = {
	"room_name": "Weapons Research",
	"room_shape": RoomShape.TShape,
	"room_desc": "Unlocks new rooms.",
	"room_category": RoomCategory.RESEARCH_ROOM,
	"power_usage": 1
}

const _data_analysis_data: Dictionary[String, Variant] = {
	"room_name": "Data Analysis",
	"room_shape": RoomShape.LShape,
	"room_desc": "If activated at the start of a turn, adds an extra room option to choose from.",
	"room_category": RoomCategory.RESEARCH_ROOM,
	"power_usage": 1
}


## COMBAT ROOMS


const _armory_data: Dictionary[String, Variant] = {
	"room_name": "Armory",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "Contains weapons to help your crew fight intruders.",
	"room_category": RoomCategory.EMERGENCY_ROOM,
	"power_usage": 1
}
