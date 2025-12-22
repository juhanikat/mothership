extends Node



var path_build_mode: bool = false:
	set(value):
		path_build_mode = value
		if path_build_mode == true:
			print("Path build mode ON")
		else:
			print("Path build mode OFF")
