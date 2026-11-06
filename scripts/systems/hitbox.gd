class_name Hitbox
extends Area3D
## พื้นที่โจมตี — เปิดเฉพาะช่วง Active ของท่าโจมตี
## Task 2.10 — Hit Detection / Task 2.12 — Hitstop + ประกายไฟเมื่อโดน
## ตีโดน Hurtbox ได้ครั้งเดียวต่อการเปิดหนึ่งครั้ง (ไม่โดนซ้ำหลายเฟรม)

## ถูก Parry สำเร็จ — เจ้าของท่า (เช่น ศัตรู) ใช้สัญญาณนี้เข้าสถานะเสียหลัก
signal parried
## ตีโดนและดาเมจเข้าจริง — เจ้าของใช้สั่นกล้อง ฯลฯ
signal hit_landed(hurtbox: Hurtbox)

@export var damage: int = 10
## false = ท่านี้ Parry ไม่ได้ (ต้องหลบเท่านั้น)
@export var parryable: bool = true

@export_group("Feedback")
## เกมหยุดนานแค่ไหนเมื่อโดน (วินาทีจริง) — 0.06 ≈ 4 เฟรม, 0 = ปิด
@export var hitstop_seconds: float = 0.06
@export var spark_color: Color = Color(1, 0.9, 0.4)
## เสียงตอนตีโดน (ไฟล์ใน assets/audio/sfx/)
@export var hit_sound: StringName = &"hit"
@export var hit_volume_db: float = 0.0
## แสดงกล่องสีเหลือง (ใช้ตอนดีบักเท่านั้น)
@export var show_debug_box: bool = false

var _already_hit: Array[Area3D] = []


func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)
	_set_visual(false)


## เรียกตอนเริ่มเฟรม Active
func activate() -> void:
	_already_hit.clear()
	monitoring = true
	_set_visual(true)


## เรียกตอนจบเฟรม Active หรือเมื่อท่าถูกขัด
func deactivate() -> void:
	set_deferred("monitoring", false)
	_set_visual(false)


## Hurtbox เรียกเมื่อผู้เล่น Parry ท่านี้สำเร็จ
func got_parried() -> void:
	deactivate()
	parried.emit()


func _on_area_entered(area: Area3D) -> void:
	if not (area is Hurtbox) or _already_hit.has(area):
		return
	_already_hit.append(area)
	var hurtbox := area as Hurtbox
	if hurtbox.receive_hit(self):
		# จุดปะทะ: ผิวด้านหน้าของตัวที่ถูกตี ฝั่งที่หันหาผู้โจมตี
		var target: Vector3 = hurtbox.get_center()
		var to_attacker: Vector3 = get_parent().global_position - target
		to_attacker.y = 0.0
		var contact: Vector3 = target
		if to_attacker.length() > 0.01:
			contact += to_attacker.normalized() * 0.35
		HitSpark.spawn(get_tree().current_scene, contact, spark_color)
		Sfx.play_3d(get_tree().current_scene, hit_sound, contact, hit_volume_db)
		if hitstop_seconds > 0.0:
			HitStop.apply(0.05, hitstop_seconds)
		hit_landed.emit(hurtbox)


## กล่องสีเหลืองโปร่ง — แสดงเฉพาะเมื่อเปิด show_debug_box
func _set_visual(on: bool) -> void:
	if has_node("Visual"):
		$Visual.visible = on and show_debug_box
