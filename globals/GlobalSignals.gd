extends Node


## Put signals here
signal room_connected(connector1: Connector, connector2: Connector)
signal path_build_mode_toggled(new_path_build_mode: bool)

# path length is in rooms
signal path_completed(path_start_room: Room, path_end_room: Room, path_length: int)

signal crew_added(amount: int)
signal crew_removed(amount: int)
