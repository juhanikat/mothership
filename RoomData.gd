extends Script
class_name RoomData



enum RoomShape {LShape, SmallSquareShape, BigSquareShape}
enum RoomType {COMMAND_ROOM, POWER_PLANT, ENGINE_ROOM, FUEL_STORAGE, CREW_QUARTERS, CANTEEN, GARDEN}
enum RoomCategory {CREW_ROOM, MAINTENANCE_ROOM, RESEARCH_ROOM, COMBAT_ROOM, LUXURY_ROOM, SPECIAL_ROOM}

const room_colors = {
	RoomCategory.CREW_ROOM: Color(0.212, 0.561, 0.812),
	RoomCategory.MAINTENANCE_ROOM: Color(0.957, 0.588, 0.098),
	RoomCategory.RESEARCH_ROOM: Color(0.678, 0.0, 0.68),
	RoomCategory.COMBAT_ROOM: Color(0.681, 0.257, 0.219),
	RoomCategory.LUXURY_ROOM: Color(0.394, 0.834, 0.113),
	RoomCategory.SPECIAL_ROOM: Color(0.904, 0.741, 0.651)
	}


## NOTE: Use this dict in other scripts.
const room_data = {
	RoomType.COMMAND_ROOM: _command_room_data,
	RoomType.POWER_PLANT: _power_plant_data,
	RoomType.ENGINE_ROOM: _engine_room_data,
	RoomType.FUEL_STORAGE: _fuel_storage_data,
	RoomType.CREW_QUARTERS: _crew_quarters_data,
	RoomType.CANTEEN: _canteen_data,
	RoomType.GARDEN: _garden_data
}


## TODO: Use classes instead of dicts here to get autocomplete?
const _command_room_data: Dictionary[String, Variant] = {
	"room_name": "Command Room",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "test",
	"room_category": RoomCategory.SPECIAL_ROOM,
	"power_usage": 0
}

const _power_plant_data: Dictionary[String, Variant] = {
	"room_name": "Power Plant",
	"room_shape": RoomShape.LShape,
	"room_desc": "Provides power for nearby rooms. Needs a Fuel Storage within 3 rooms to activate.",
	"room_category": RoomCategory.SPECIAL_ROOM,
	"power_usage": 0,
	"power_supply": {"capacity": 10, "range": 5}
}

const _engine_room_data: Dictionary[String, Variant] = {
	"room_name": "Engine Room",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "",
	"room_category": RoomCategory.SPECIAL_ROOM,
	"power_usage": 3
}

const _fuel_storage_data: Dictionary[String, Variant] = {
	"room_name": "Fuel Storage",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "",
	"room_category": RoomCategory.MAINTENANCE_ROOM,
	"power_usage": 0,
	"always_activated": true
}

const _crew_quarters_data: Dictionary[String, Variant] = {
	"room_name": "Crew Quarters",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "Has to be connected to a Canteen through Crew rooms to activate.",
	"room_category": RoomCategory.CREW_ROOM,
	"power_usage": 1,
	"crew_supply": 4
}

const _canteen_data: Dictionary[String, Variant] = {
	"room_name": "Canteen",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "Must be placed adjacent to at least one Crew room.",
	"room_category": RoomCategory.CREW_ROOM,
	"power_usage": 1
}

const _garden_data: Dictionary[String, Variant] = {
	"room_name": "Garden",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "Raises your crew quarter limit by 2.",
	"room_category": RoomCategory.LUXURY_ROOM,
	"power_usage": 0,
	"crew_quarters_limit_increase": 2
}




## Maps a RoomShape to the rooms to a Vector indicating the room's width and height.
## NOTE: Remember to update these if you change the room shapes!
const room_shape_dimensions = {
	RoomShape.LShape: Vector2(128, 128),
	RoomShape.SmallSquareShape: Vector2(64, 64),
	RoomShape.BigSquareShape: Vector2(128, 128)
}

## Maps the shape of a room to the top left corner of the room the info should be.
const room_info_pos = {
	RoomShape.LShape: Vector2(-64, -64),
	RoomShape.SmallSquareShape: Vector2(-32, -32),
	RoomShape.BigSquareShape: Vector2(-64, -64),
}

## Maps a RoomShape to an Array containing the locations of its connectors.
## NOTE: Add some offset to these so the rooms are not adjacent when snapped,
## otherwise room area detection does not work!
const room_connectors = {
	RoomShape.LShape: [Vector2(0, -72), Vector2(72, -32), Vector2(-32, 72), Vector2(-72, 0)],
	RoomShape.SmallSquareShape: [Vector2(0, -40),Vector2(40, 0), Vector2(0, 40), Vector2(-40, 0)],
	RoomShape.BigSquareShape: [Vector2(0, -72), Vector2(72, 0), Vector2(0, 72), Vector2(-72, 0)],
}
