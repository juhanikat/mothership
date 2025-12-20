extends Node

## NOTE: Snap the room that holds emitters_connector to the room that holds other_connector
## not the other way around
signal connectors_snapped(emitters_connector: Area2D, other_connector: Area2D, emitter_room: Room, other_room: Room)
