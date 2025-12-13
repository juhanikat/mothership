extends Script
class_name RoomData

## Fields that can be included in a room data dict:
## room_name: String = Name of the room.
## room_shape: RoomShape = Shape of the room.
## power_usage: int = How much power the room uses.

enum RoomShape {LShape, SquareShape}
enum RoomType {COMMAND_ROOM, POWER_PLANT, CREW_QUARTERS}

# NOTE: Remember to modify these if you change the polygons!
const LShape_dimensions = Vector2(128, 128)
const SquareShape_dimensions = Vector2(64, 64)

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
