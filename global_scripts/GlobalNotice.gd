extends Node


@onready var notice_node: Notice = get_tree().root.get_node("Main").get_node("Notice")


func display(text: String, type: String = "info", time: float = 2):
	notice_node.display(text, type, time)
