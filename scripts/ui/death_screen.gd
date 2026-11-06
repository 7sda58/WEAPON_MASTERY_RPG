extends CanvasLayer
## หน้าจอตาย — จอมืดลง ขึ้น YOU DIED แล้วรอกด R เพื่อเกิดใหม่

signal respawn_requested

@onready var overlay: ColorRect = $Overlay
@onready var title: Label = $Title
@onready var hint: Label = $Hint

var _can_respawn: bool = false


func _ready() -> void:
	visible = false


func show_death() -> void:
	visible = true
	_can_respawn = false
	overlay.modulate.a = 0.0
	title.modulate.a = 0.0
	hint.modulate.a = 0.0
	title.scale = Vector2.ONE * 1.3
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(overlay, "modulate:a", 1.0, 1.0)
	t.parallel().tween_property(title, "modulate:a", 1.0, 0.8).set_delay(0.3)
	t.parallel().tween_property(title, "scale", Vector2.ONE, 1.4).set_delay(0.3) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(hint, "modulate:a", 1.0, 0.4)
	t.tween_callback(func() -> void: _can_respawn = true)


func hide_death() -> void:
	visible = false
	_can_respawn = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _can_respawn:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_viewport().set_input_as_handled()
		respawn_requested.emit()
