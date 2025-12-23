extends Area2D
class_name Connector


@export var collision_polygon: CollisionPolygon2D
@export var nav_region: NavigationRegion2D

@export var texture_polygon: Polygon2D
var connector_color = Color("bfb7be")



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


func connected_to() -> Variant:
	## Returns the connector that is connected to this one (both connectors must
	## fully overlap, or null otherwise.
	## Idk if this is used for anything at the moment.
	for connector: Connector in get_tree().get_nodes_in_group("Connector"):
		if connector == self:
			continue
		if connector.global_position == global_position:
			return connector
	return null
