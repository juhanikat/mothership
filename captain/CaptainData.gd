extends Node
class_name CaptainData


## Holds data related to the selection of new rooms etc.
## Actual HUD for the room selection is elsewhere.
## Also check out CaptainFunctions.gd.

# Only used when starting the game to place critical rooms.
enum StartingOrder {POWER_PLANT_ORDER, ENGINE_ROOM_ORDER, FUEL_STORAGE_ORDER, COMMAND_ROOM_ORDER}

# The normal orders.
enum Order {NEUTRAL_ORDER, CARGO_BAY_ORDER, COMBAT_WARNING_ORDER, COMBAT_CRITICAL_ORDER, CREW_ORDER}

const ROOMS = RoomData.RoomType
# If an order has a "room_category" array, then any room that is in those categories can appear.
# Some rooms have a special key (in RoomData) that excludes them from this?
const ROOM_CATEGORIES = RoomData.RoomCategory



## Use these in other scripts.
const starting_order = {
	"description": "We need a few basic rooms to get started.",
	"rooms": [ROOMS.POWER_PLANT, ROOMS.FUEL_STORAGE, ROOMS.COMMAND_ROOM]
	}

# Orders that can be chosen randomly
const basic_orders = {
	Order.NEUTRAL_ORDER: _neutral_order,
	#Order.COMBAT_WARNING_ORDER: _combat_warning_order,
	#Order.COMBAT_CRITICAL_ORDER: _combat_critical_order
	}

# These orders can appear e.g. on specific turns
const special_orders = {
	Order.CARGO_BAY_ORDER: _cargo_bay_order
}


const _neutral_order = {
	"description": "The Captain has no orders for you. Choose the room you think would best fit our current situation.",
	"room_categories": [
		ROOM_CATEGORIES.CREW_ROOM,
		ROOM_CATEGORIES.MAINTENANCE_ROOM,
		ROOM_CATEGORIES.COMBAT_ROOM,
		ROOM_CATEGORIES.RESEARCH_ROOM,
		ROOM_CATEGORIES.LUXURY_ROOM
	],
	"choose_from": 3
	}

const _cargo_bay_order = {
	"description": "The Commander wants you to build a Cargo Bay to import and export resources.",
	"rooms": [
		ROOMS.CARGO_BAY
	]
	}

const _combat_warning_order = {
	"description": "We've picked up some potentially hostile activity nearby.",
	"room_categories": [
		ROOM_CATEGORIES.COMBAT_ROOM,
	],
	"choose_from": 3
	}

const _combat_critical_order = {
	"description": "Hostile activity imminent!",
	"room_categories": [
		ROOM_CATEGORIES.COMBAT_ROOM,
	],
	"choose_from": 3
	}
