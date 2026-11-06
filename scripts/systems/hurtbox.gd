class_name Hurtbox
extends Area3D
## พื้นที่รับการโจมตี — ส่งดาเมจต่อให้ HealthComponent
## Task 2.10 — Hit Detection / Task 2.15 — รองรับ Parry

signal hit_received(hitbox: Hitbox)
## Parry สำเร็จ — ไม่เสียเลือด
signal parried(hitbox: Hitbox)

## ลาก HealthComponent ของตัวเองมาใส่ช่องนี้ใน Inspector
@export var health: HealthComponent

## เปิดระหว่างหน้าต่าง Parry ของเจ้าของ
var parry_active: bool = false
## ตัวคูณดาเมจที่รับ — เช่น 2.0 ตอนศัตรูเสียหลัก (คริติคอล)
var damage_multiplier: float = 1.0


func _ready() -> void:
	monitoring = false
	monitorable = true


func receive_hit(hitbox: Hitbox) -> void:
	if parry_active and hitbox.parryable:
		hitbox.got_parried()
		parried.emit(hitbox)
		return
	if health:
		health.take_damage(roundi(hitbox.damage * damage_multiplier))
	hit_received.emit(hitbox)
