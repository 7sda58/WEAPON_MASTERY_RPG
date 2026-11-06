class_name Hitbox
extends Area3D
## พื้นที่โจมตี — เปิดเฉพาะช่วง Active ของท่าโจมตี
## Task 2.10 — Hit Detection
## ตีโดน Hurtbox ได้ครั้งเดียวต่อการเปิดหนึ่งครั้ง (ไม่โดนซ้ำหลายเฟรม)

## ถูก Parry สำเร็จ — เจ้าของท่า (เช่น ศัตรู) ใช้สัญญาณนี้เข้าสถานะเสียหลัก
signal parried

@export var damage: int = 10
## false = ท่านี้ Parry ไม่ได้ (ต้องหลบเท่านั้น) — Task 3.16 จะใช้สัญญาณสีแดงบอกผู้เล่น
@export var parryable: bool = true

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
	if area is Hurtbox and not _already_hit.has(area):
		_already_hit.append(area)
		area.receive_hit(self)


## แสดงกล่องสีเหลืองโปร่ง (ชั่วคราว จนกว่าจะมีเอฟเฟกต์จริง)
func _set_visual(on: bool) -> void:
	if has_node("Visual"):
		$Visual.visible = on
