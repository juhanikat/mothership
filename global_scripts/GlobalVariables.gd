extends Node


var turn: int = 1
var room_is_picked: bool = false

# currently picked crew member, if any
var picked_crew = null

# DEV OPTIONS
var events_disabled: bool = true
const CREATE_TESTING_ROOMS: bool = true
const NO_CARGO_BAY_REQUIREMENT: bool = true
const NO_GAME_OVER: bool = true
const CAN_PICK_MULTIPLE_ROOMS: bool = false
