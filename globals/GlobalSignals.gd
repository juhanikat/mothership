extends Node


## Put signals here
signal room_connected(connector1: Connector, connector2: Connector)
signal path_build_mode_toggled(new_path_build_mode: bool)

# path length is in rooms
signal path_completed(path_start_room: Room, path_end_room: Room, path_length: int)

# Emitted when "Next Turn" is pressed
signal turn_advanced

signal crew_added(amount: int)
signal crew_removed(amount: int)

signal crew_quarters_limit_raised(amount: int)
signal crew_quarters_limit_lowered(amount: int)

# For cargo bay
signal cargo_bay_order_made(order_type: String, cargo_bay: Room)
