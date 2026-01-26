extends Node


## Put signals here
signal room_connected(connector1: Connector, connector2: Connector)
signal path_build_mode_toggled(new_path_build_mode: bool)

# path length is in rooms
signal path_completed(path_start_room: Room, path_end_room: Room, path_length: int)

# Emitted when "Next Turn" is pressed
# NOTE: Main will listen to this and it handles the "next_turn()" function
# inside RoomGameplay (and possibly elsewhere), since things have to be done in order
signal turn_advanced

# For cargo bay and HUD interactions
signal delivery_status_changed(new_status: Dictionary)
signal cargo_bay_order_made(delivery: Dictionary)

signal crew_added(amount: int)
signal crew_removed(amount: int)

signal crew_quarters_limit_raised(amount: int)
signal crew_quarters_limit_lowered(amount: int)
