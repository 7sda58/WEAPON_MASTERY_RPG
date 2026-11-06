class_name HitStop
extends RefCounted
## Hitstop / Slow-motion — หยุดหรือชะลอเกมชั่วครู่ให้รู้สึกถึงแรงกระแทก
## Task 2.12 — Combat Feedback
## เรียกใช้จากที่ไหนก็ได้: HitStop.apply(0.05, 0.06)  ← เกมช้าเหลือ 5% นาน 0.06 วินาที (เวลาจริง)
## ถ้าเรียกซ้อนกัน ตัวที่เรียกล่าสุดเป็นตัวกำหนดเวลาจบ

static var _token: int = 0


static func apply(time_scale: float, real_seconds: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	_token += 1
	var my_token: int = _token
	Engine.time_scale = time_scale
	await tree.create_timer(real_seconds, true, false, true).timeout
	if my_token == _token:
		Engine.time_scale = 1.0
