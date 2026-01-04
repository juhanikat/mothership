extends Node
class_name Captain


## Holds functions and data related to the selection of new rooms etc.
## Actual HUD for the room selection is elsewhere.
enum Order {NEUTRAL_ORDER}
const ROOMS = RoomData.RoomType

const neutral_order = {
	"description": "The Captain has no orders for you. Choose the room you think would best fit our current situation.",
	"rooms": ROOMS.CREW_QUARTERS}

## Use this in other scripts.
const orders = {Order.NEUTRAL_ORDER: neutral_order}
