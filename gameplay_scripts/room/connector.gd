class_name Connector
extends Area2D

@export var collision_polygon: CollisionPolygon2D
@export var nav_region: NavigationRegion2D
@export var texture_polygon: Polygon2D
@export var check_connection_timer: Timer

var connector_color = Color("bfb7be")
var hovering: bool = false


func _ready() -> void:
	create_navigation_polygon()
	create_texture()


func create_texture() -> void:
	texture_polygon.polygon = collision_polygon.polygon
	texture_polygon.color = connector_color


func create_navigation_polygon() -> void:
	## Creates a navigation polygon for this connector.
	var new_nav_polygon = NavigationPolygon.new()
	new_nav_polygon.agent_radius = 0 # otherwise the shape will be too small to exist!
	new_nav_polygon.add_outline(collision_polygon.polygon)
	nav_region.navigation_polygon = new_nav_polygon
	nav_region.bake_navigation_polygon()


func delete_navigation_region() -> void:
	nav_region.queue_free()


func get_parent_room() -> Room:
	## Returns the room that is the parent of this Connector.
	var all_rooms = get_tree().get_nodes_in_group("Room")
	for room in all_rooms:
		if room.is_ancestor_of(self):
			return room
	return null


func check_deletion() -> void:
	var overlapping_conns: Array[Connector] = get_overlapping_connectors()
	if len(overlapping_conns) > 0:
		if not (len(overlapping_conns) == 1 and connected_to() == overlapping_conns[0]):
			queue_free()
	var overlapping_rooms: Array[Room] = get_overlapping_rooms()
	if len(overlapping_rooms) > 0:
		# Connectors can overlap exactly one room (the one they are connected to), this is easier than to fix the overlap
		if not (len(overlapping_rooms) == 1 and connected_to() and connected_to() in overlapping_rooms[0].get_own_connectors()):
			queue_free()


func get_overlapping_connectors() -> Array[Connector]:
	## Returns all connectors that are overlapping this one (partially or fully).
	## Used to delete those connectors after the room is placed.
	var overlapping_areas = get_overlapping_areas()
	var overlapping_connectors: Array[Connector] = []
	for connector: Connector in get_tree().get_nodes_in_group("Connector"):
		if connector == self:
			continue
		if connector in overlapping_areas:
			overlapping_connectors.append(connector)
	return overlapping_connectors


## Returns all Rooms that are overlapping this connector (partially or fully).
func get_overlapping_rooms() -> Array[Room]:
	var overlapping_areas = get_overlapping_areas()
	var overlapping_rooms: Array[Room] = []
	var overlapping_conns: Array[Connector] = []
	for area in overlapping_areas:
		if area.is_in_group("Room") and area != get_parent_room():
			overlapping_rooms.append(area)
		elif area.is_in_group("Connector"):
			overlapping_conns.append(area)
	return overlapping_rooms


## Returns the connector that is connected to this one (both connectors must fully overlap),
## or null otherwise.
## Used when a room is connected to see which rooms must have their "adjacent_rooms" lists updated.
func connected_to() -> Variant:
	for connector: Connector in get_tree().get_nodes_in_group("Connector"):
		if connector == self:
			continue
		if connector.global_position == global_position:
			return connector
	return null


func _on_mouse_entered() -> void:
	hovering = true


func _on_mouse_exited() -> void:
	hovering = false
