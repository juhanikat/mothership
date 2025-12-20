extends Script
class_name RoomData

## Fields that can be included in a room data dict:
## room_name: String = Name of the room.
## room_shape: RoomShape = Shape of the room.
## power_usage: int = How much power the room uses.

enum RoomShape {LShape, SquareShape}
enum RoomType {COMMAND_ROOM, POWER_PLANT, CREW_QUARTERS}

# NOTE: Remember to modify these if you change the polygons!


const _command_room_data: Dictionary[String, Variant] = {
	"room_name": "Command Room",
	"room_shape": RoomShape.SquareShape,
	"power_usage": 0
}

const _power_plant_data: Dictionary[String, Variant] = {
	"room_name": "Power Plant",
	"room_shape": RoomShape.LShape,
	"power_usage": 0
}

## Use this dict in tile.gd.
const room_data = {
	RoomType.COMMAND_ROOM: _command_room_data,
	RoomType.POWER_PLANT: _power_plant_data
}


## Maps a RoomShape to the rooms to a Vector indicating the room's width and height.
## NOTE: Remember to update these if you change the room shapes!
const room_shape_dimensions = {
	RoomShape.LShape: Vector2(128, 128),
	RoomShape.SquareShape: Vector2(64, 64)
}


## Maps a RoomShape to an Array containing the locations of its connectors.
## NOTE: Add some offset to these so the rooms are not adjacent when snapped,
## otherwise room area detection does not work!
const room_connectors = {
	RoomShape.LShape: [Vector2(0, -72), Vector2(72, -32), Vector2(-32, 72), Vector2(-72, 0)],
	RoomShape.SquareShape: [Vector2(0, -40),Vector2(40, 0), Vector2(0, 40), Vector2(-40, 0)]
}
