class_name HealthComponent
extends Node
## ระบบ HP ใช้ได้ทั้งผู้เล่นและศัตรู — ใส่เป็น node ลูกของตัวละคร
## Task 2.7 — Health System

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal died

@export var max_health: int = 100

var current_health: int
var is_dead: bool = false
## เปิดไว้ = ไม่รับดาเมจ (ใช้กับ i-frame ของ Dodge ใน Task 2.11)
var invincible: bool = false


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if is_dead or invincible or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		is_dead = true
		died.emit()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


## เติม HP เต็มและฟื้นจากความตาย (ใช้ตอนเกิดใหม่)
func reset() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
