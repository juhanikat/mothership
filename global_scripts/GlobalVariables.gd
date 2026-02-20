extends Node


var turn: int = 1
var room_is_picked: bool = false

# currently picked crew member, if any
var picked_crew = null

# DEV OPTIONS
var events_disabled: bool = true
var create_testing_rooms: bool = true
var NO_CARGO_BAY_REQUIREMENT: bool = true
var NO_GAME_OVER: bool = true
var CAN_PICK_MULTIPLE_ROOMS: bool = false
