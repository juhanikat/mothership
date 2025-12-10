extends CanvasLayer


@onready var main: Main = get_parent()

func _on_l_shape_button_pressed() -> void:
	main.spawn_tile(Tile.TileType.LShape)


func _on_square_button_pressed() -> void:
	main.spawn_tile(Tile.TileType.SquareShape)
