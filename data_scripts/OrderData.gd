extends Node
class_name OrderData


## Holds data related to the selection of new rooms etc.
## Actual HUD for the room selection is elsewhere.
## Also check out CaptainFunctions.gd.

# The normal orders.
enum Order {NEUTRAL_ORDER_1, NEUTRAL_ORDER_2, NEUTRAL_ORDER_3, STARTING_ORDER, CARGO_BAY_ORDER, RESEARCH_ROOM_ORDER}

const ROOMS = RoomData.RoomType
const ROOM_CATEGORIES = RoomData.RoomCategory



# Orders that can be chosen randomly
const basic_orders = {
	Order.NEUTRAL_ORDER_1: _neutral_order_1,
	#Order.NEUTRAL_ORDER_2: _neutral_order_2,
	#Order.NEUTRAL_ORDER_3: _neutral_order_3,
	}

# These orders can appear e.g. on specific turns
const special_orders = {
	Order.CARGO_BAY_ORDER: _cargo_bay_order,
	Order.RESEARCH_ROOM_ORDER: _research_room_order,
	Order.STARTING_ORDER: _starting_order
}

const _starting_order = {
	"description": "We need a few basic rooms to get started.",
	"rooms": [ROOMS.POWER_PLANT, ROOMS.FUEL_STORAGE, ROOMS.COMMAND_ROOM]
	}

const _neutral_order_1 = {
	"description": "The Commander has no orders for you. Choose the room you think would best fit our current situation.",
	"room_categories_dict": {
		ROOM_CATEGORIES.CREW_ROOM: 1,
		ROOM_CATEGORIES.MAINTENANCE_ROOM: 2,
		#ROOM_CATEGORIES.EMERGENCY_ROOM: 1,
		#ROOM_CATEGORIES.LUXURY_ROOM: 1,
	},
}

# neutral order 2 and 3 are unlocked by a research room?
const _neutral_order_2 = {
	"description": "The Commander has no orders for you. Choose the room you think would best fit our current situation.",
	"room_categories_dict": {
		ROOM_CATEGORIES.CREW_ROOM: 1,
		ROOM_CATEGORIES.MAINTENANCE_ROOM: 2,
		ROOM_CATEGORIES.EMERGENCY_ROOM: 1,
		#ROOM_CATEGORIES.LUXURY_ROOM: 1,
	},
}

const _neutral_order_3 = {
	"description": "The Commander has no orders for you. Choose the room you think would best fit our current situation.",
	"room_categories_dict": {
		ROOM_CATEGORIES.CREW_ROOM: 1,
		ROOM_CATEGORIES.MAINTENANCE_ROOM: 2,
		ROOM_CATEGORIES.EMERGENCY_ROOM: 1,
		ROOM_CATEGORIES.LUXURY_ROOM: 1,
	},
}

const _research_room_order = {
	"description": "It's time to build a new research station.",
	"room_categories_array": [
		ROOM_CATEGORIES.RESEARCH_ROOM,
	]
	}

const _cargo_bay_order = {
	"description": "The Commander wants you to build a Cargo Bay to import and export resources.",
	"rooms": [
		ROOMS.CARGO_BAY
	]
	}
