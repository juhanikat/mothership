extends Node

var turn: int = 1
var room_is_picked: bool = false

const STARTING_RESOURCES: int = 20
var resources: int = STARTING_RESOURCES

# currently picked crew member, if any
var picked_crew = null

# DEV OPTIONS
var events_disabled: bool = true
const INFINITE_RESOURCES: bool = true # rooms still cost resources, but you can go negative
const CREATE_TESTING_ROOMS: bool = true
const NO_STARTING_ORDER: bool = true
const NO_CARGO_BAY_REQUIREMENT: bool = true
const NO_GAME_OVER: bool = false
const CAN_PICK_MULTIPLE_ROOMS: bool = false
