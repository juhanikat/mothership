extends CanvasLayer
class_name Notice

@export var panel_container: PanelContainer
@export var notification_text_label: RichTextLabel
@export var notification_timer: Timer
@export var animation_player: AnimationPlayer


func display(text: String, type: String = "info", time: float = 2) -> void:
	notification_text_label.text = text
	var stylebox = StyleBoxFlat.new()
	match type:
		"info":
			stylebox.bg_color = Color(0.0, 0.0, 0.0, 0.686)
		"warning":
			stylebox.bg_color = Color(1.0, 0.608, 0.129, 0.769)
	panel_container.add_theme_stylebox_override("panel", stylebox)

	animation_player.play("show_notification")
	notification_timer.start(time)


func _on_timer_timeout() -> void:
	animation_player.play("hide_notification")
