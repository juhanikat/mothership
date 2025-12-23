extends Script
class_name RoomData

## Fields that can be included in a room data dict:
## room_name: String = Name of the room.
## room_shape: RoomShape = Shape of the room.
## power_usage: int = How much power the room uses.

enum RoomShape {LShape, SmallSquareShape, BigSquareShape}
enum RoomType {COMMAND_ROOM, POWER_PLANT, CREW_QUARTERS}

const room_colors = [Color("ff5a55"), Color("77a6fb"), Color("e2c964")]


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
	"room_desc": "Provides power for nearby rooms.",
	"power_usage": 0
}

const _crew_quarters_data: Dictionary[String, Variant] = {
	"room_name": "Crew Quarters",
	"room_shape": RoomShape.BigSquareShape,
	"room_desc": "abc",
	"power_usage": 1
}

## Use this dict in tile.gd.
const room_data = {
	RoomType.COMMAND_ROOM: _command_room_data,
	RoomType.POWER_PLANT: _power_plant_data,
	RoomType.CREW_QUARTERS: _crew_quarters_data
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
