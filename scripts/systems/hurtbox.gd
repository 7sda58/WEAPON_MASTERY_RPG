class_name Hurtbox
extends Area2D
## พื้นที่รับการโจมตี — ส่งดาเมจต่อให้ HealthComponent
## Task 2.10 — Hit Detection

signal hit_received(hitbox: Hitbox)

## ลาก HealthComponent ของตัวเองมาใส่ช่องนี้ใน Inspector
@export var health: HealthComponent


func _ready() -> void:
	monitoring = false
	monitorable = true


func receive_hit(hitbox: Hitbox) -> void:
	if health:
		health.take_damage(hitbox.damage)
	hit_received.emit(hitbox)
