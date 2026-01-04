extends Script
class_name RoomData

## Fields that can be included in a room data dict:
## room_name: String = Name of the room.
## room_shape: RoomShape = Shape of the room.
## power_usage: int = How much power the room uses.

enum RoomShape {LShape, SmallSquareShape, BigSquareShape}
enum RoomType {COMMAND_ROOM, POWER_PLANT, ENGINE_ROOM, FUEL_STORAGE, CREW_QUARTERS, GARDEN}

const room_colors = [Color("ff5a55"), Color("77a6fb"), Color("e2c964")]


## NOTE: Use this dict in other scripts.
const room_data = {
	RoomType.COMMAND_ROOM: _command_room_data,
	RoomType.POWER_PLANT: _power_plant_data,
	RoomType.ENGINE_ROOM: _engine_room_data,
	RoomType.FUEL_STORAGE: _fuel_storage_data,
	RoomType.CREW_QUARTERS: _crew_quarters_data,
	RoomType.GARDEN: _garden_data
}


## TODO: Use classes instead of dicts here to get autocomplete?
const _command_room_data: Dictionary[String, Variant] = {
	"room_name": "Command Room",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "test",
	"power_usage": 0
}

const _power_plant_data: Dictionary[String, Variant] = {
	"room_name": "Power Plant",
	"room_shape": RoomShape.LShape,
	"room_desc": "Provides power for nearby rooms. Needs a Fuel Storage within 3 rooms to function.",
	"power_usage": 0,
	"power_supply": {"capacity": 10, "range": 5}
}

const _engine_room_data: Dictionary[String, Variant] = {
	"room_name": "Engine Room",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "",
	"power_usage": 3
}

const _fuel_storage_data: Dictionary[String, Variant] = {
	"room_name": "Fuel Storage",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "",
	"power_usage": 0
}

const _crew_quarters_data: Dictionary[String, Variant] = {
	"room_name": "Crew Quarters",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "abc",
	"power_usage": 1
}

const _garden_data: Dictionary[String, Variant] = {
	"room_name": "Garden",
	"room_shape": RoomShape.SmallSquareShape,
	"room_desc": "Raises your crew quarter limit by 2.",
	"power_usage": 0
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
	RoomShape.BigSquareShape: [Vector2(0, -72), Vector2(72, -32), Vector2(-32, 72), Vector2(-72, 0)],
}
