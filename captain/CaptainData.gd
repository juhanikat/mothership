extends Node
class_name CaptainData


## Holds data related to the selection of new rooms etc.
## Actual HUD for the room selection is elsewhere.
## Also check out CaptainFunctions.gd.

# Only used when starting the game to place critical rooms.
enum StartingOrder {POWER_PLANT_ORDER, ENGINE_ROOM_ORDER, FUEL_STORAGE_ORDER, COMMAND_ROOM_ORDER}

# The normal orders.
enum Order {NEUTRAL_ORDER, CREW_ORDER}

const ROOMS = RoomData.RoomType



## Use these in other scripts.
const starting_orders = [_power_plant_order, _engine_room_order, _fuel_storage_order, _command_room_order]

const orders = {Order.NEUTRAL_ORDER: _neutral_order}



const _power_plant_order = {
	"description": "We need a power plant to supply power.",
	"rooms": [ROOMS.POWER_PLANT]
	}

const _fuel_storage_order = {
	"description": "Fuel storage!",
	"rooms": [ROOMS.FUEL_STORAGE]
	}

const _engine_room_order = {
	"description": "Engine room!",
	"rooms": [ROOMS.ENGINE_ROOM]
	}

const _command_room_order = {
	"description": "Command room!",
	"rooms": [ROOMS.COMMAND_ROOM]
	}


const _neutral_order = {
	"description": "The Captain has no orders for you. Choose the room you think would best fit our current situation.",
	"rooms": [ROOMS.CREW_QUARTERS],
	"choose_from": 3
	}
