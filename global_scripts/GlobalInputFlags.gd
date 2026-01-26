extends Node



var path_build_mode: bool = false:
	set(value):
		path_build_mode = value
		if path_build_mode == true:
			print("Path build mode ON")
		else:
			print("Path build mode OFF")
		GlobalSignals.path_build_mode_toggled.emit(path_build_mode)


var show_tooltips: bool = false:
	set(value):
		show_tooltips = value
		if show_tooltips == true:
			print("Tooltips are shown")
		else:
			print("Tooltips are hidden")
