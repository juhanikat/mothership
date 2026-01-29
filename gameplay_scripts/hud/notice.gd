class_name Notice
extends CanvasLayer

@export var panel_container: PanelContainer
@export var notification_text_label: RichTextLabel
@export var notification_timer: Timer
@export var animation_player: AnimationPlayer

var queue = []


## Displays a notification, or puts it into a queue.
## New notification is ignored if the current notification or the next notification
## in the queue has the same content.
func display(text: String, type: String = "info", time: float = 2) -> void:
	if notification_text_label.text == text or (len(queue) > 0 and queue[0].text == text):
		return
	if animation_player.is_playing() or not notification_timer.is_stopped():
		queue.append({ "text": text, "type": type, "time": time })
		return

	notification_text_label.text = text
	var stylebox = StyleBoxFlat.new()
	match type:
		"info":
			stylebox.bg_color = Color(0.0, 0.0, 0.0, 0.686)
		"warning":
			stylebox.bg_color = Color(1.0, 0.608, 0.129, 0.769)
	panel_container.add_theme_stylebox_override("panel", stylebox)

	show()
	animation_player.play("show_notification")
	notification_timer.start(time)


func _on_timer_timeout() -> void:
	animation_player.play("hide_notification")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hide_notification":
		notification_text_label.text = ""
		hide()
		if len(queue) > 0:
			var next_notice = queue.pop_front()
			display(next_notice.text, next_notice.type, next_notice.time)
