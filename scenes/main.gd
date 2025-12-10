extends Node2D
class_name Main


var tile_scene = load("res://scenes/tile.tscn")
var tile_spawn_pos: Vector2 = Vector2(0, 0)

func _ready() -> void:
	var new_tile = tile_scene.instantiate()
	new_tile.type = Tile.TileType.SquareShape
	add_child(new_tile)
	new_tile.position = tile_spawn_pos



func spawn_tile(tile_type: Tile.TileType):
	var new_tile = tile_scene.instantiate()
	new_tile.type = tile_type
	for tile in get_tree().get_nodes_in_group("Tile"):
		if tile.global_position == tile_spawn_pos:
			print("Cannot spawn new tile on top of existing one")
			return

	add_child(new_tile)
	new_tile.global_position = tile_spawn_pos
