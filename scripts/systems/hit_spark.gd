class_name HitSpark
extends CPUParticles3D
## ประกายไฟ + แสงวาบ ณ จุดปะทะ — สร้างแล้วลบตัวเองอัตโนมัติ
## Task 2.12 — Combat Feedback
## เรียกใช้: HitSpark.spawn(get_tree().current_scene, ตำแหน่ง, สี)


static func spawn(world: Node, pos: Vector3, color: Color = Color(1, 0.9, 0.4), amount_count: int = 12) -> void:
	# --- ประกายไฟกระจายสั้น ๆ รอบจุดปะทะ ---
	var p := HitSpark.new()
	p.emitting = false            # ห้ามปล่อยก่อนย้ายไปจุดปะทะ (ค่าเริ่มต้นของ Godot คือ true)
	p.local_coords = true         # อนุภาคอยู่กับตำแหน่งของ node เสมอ
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.07, 0.07)
	quad.material = mat
	p.mesh = quad
	p.amount = amount_count
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.22
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -6.0, 0)
	p.damping_min = 6.0
	p.damping_max = 10.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	p.color = color
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = pos              # ตั้งตำแหน่งก่อนเข้าฉาก (ฉากหลักอยู่ที่จุด 0,0,0)
	world.add_child(p)
	p.global_position = pos
	p.restart()                   # เริ่มปล่อยประกายที่จุดปะทะ
	p.finished.connect(p.queue_free)

	# --- แสงวาบรูปดาว ขยายแล้วหาย ---
	var flash := MeshInstance3D.new()
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.no_depth_test = true
	fmat.albedo_color = Color(color.r, color.g, color.b, 0.9)
	var fquad := QuadMesh.new()
	fquad.size = Vector2(0.55, 0.12)
	fquad.material = fmat
	flash.mesh = fquad
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var flash2 := flash.duplicate() as MeshInstance3D
	flash.position = pos
	world.add_child(flash)
	flash.global_position = pos
	flash.add_child(flash2)
	flash2.rotation.z = PI / 2.0   # แท่งตั้ง + แท่งนอน = กากบาท
	flash.rotation.z = randf_range(-0.6, 0.6)
	flash.scale = Vector3.ONE * 0.4
	var t := flash.create_tween().set_parallel(true)
	t.tween_property(flash, "scale", Vector3.ONE * 1.2, 0.1)
	t.tween_property(fmat, "albedo_color:a", 0.0, 0.12).set_delay(0.03)
	t.chain().tween_callback(flash.queue_free)
