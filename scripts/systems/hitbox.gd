class_name Hitbox
extends Area2D
## พื้นที่โจมตี — เปิดเฉพาะช่วง Active ของท่าโจมตี
## Task 2.10 — Hit Detection
## ตีโดน Hurtbox ได้ครั้งเดียวต่อการเปิดหนึ่งครั้ง (ไม่โดนซ้ำหลายเฟรม)

@export var damage: int = 10

var _already_hit: Array[Area2D] = []


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


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and not _already_hit.has(area):
		_already_hit.append(area)
		area.receive_hit(self)


## แสดงกรอบสีเหลือง (ชั่วคราว จนกว่าจะมี Animation จริง)
func _set_visual(on: bool) -> void:
	if has_node("Visual"):
		$Visual.visible = on
