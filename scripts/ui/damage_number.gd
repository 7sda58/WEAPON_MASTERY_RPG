class_name DamageNumber
extends Label3D
## ตัวเลข (หรือข้อความ) ลอยขึ้นเหนือหัวแล้วจางหาย — หันเข้ากล้องเสมอ
## เรียกใช้: DamageNumber.spawn(get_tree().current_scene, global_position, 10)


static func spawn(world: Node, pos: Vector3, amount: int, color: Color = Color.WHITE) -> void:
	spawn_text(world, pos, str(amount), color)


static func spawn_text(world: Node, pos: Vector3, text: String, color: Color = Color.WHITE) -> void:
	var n := DamageNumber.new()
	n.text = text
	n.modulate = color
	n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.no_depth_test = true          # มองเห็นแม้มีของบัง
	n.fixed_size = true             # ขนาดบนจอเท่าเดิมไม่ว่าซูมแค่ไหน
	n.pixel_size = 0.0012
	n.font_size = 40
	n.outline_size = 12
	n.outline_modulate = Color(0, 0, 0, 1)
	n.render_priority = 10
	world.add_child(n)
	n.global_position = pos + Vector3(randf_range(-0.25, 0.25), 1.9, 0.0)
	n._play()


func _play() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "position:y", position.y + 0.6, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.3)
	t.tween_property(self, "outline_modulate:a", 0.0, 0.35).set_delay(0.3)
	t.chain().tween_callback(queue_free)
