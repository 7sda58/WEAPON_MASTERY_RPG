class_name DamageNumber
extends Label
## ตัวเลข (หรือข้อความ) ลอยขึ้นแล้วจางหาย
## เรียกใช้: DamageNumber.spawn(get_tree().current_scene, global_position, 10)


static func spawn(world: Node, pos: Vector2, amount: int, color: Color = Color.WHITE) -> void:
	spawn_text(world, pos, str(amount), color)


static func spawn_text(world: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var n := DamageNumber.new()
	n.text = text
	n.modulate = color
	n.z_index = 100
	n.add_theme_font_size_override("font_size", 10)
	n.add_theme_color_override("font_outline_color", Color.BLACK)
	n.add_theme_constant_override("outline_size", 3)
	world.add_child(n)
	# ตั้งเหนือหัวตัวละคร สุ่มเยื้องซ้ายขวาเล็กน้อยไม่ให้ตัวเลขซ้อนกัน
	n.global_position = pos + Vector2(randf_range(-8.0, 2.0) - 3.0 * (text.length() - 1), -38.0)
	n._play()


func _play() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "position:y", position.y - 14.0, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.3)
	t.chain().tween_callback(queue_free)
