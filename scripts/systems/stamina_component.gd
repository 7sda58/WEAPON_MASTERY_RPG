class_name StaminaComponent
extends Node
## ระบบ Stamina — ใช้ตอนโจมตีและหลบ ฟื้นเองหลังหยุดใช้ครู่หนึ่ง
## Task 2.8 — Stamina System

signal stamina_changed(current: float, maximum: float)

@export var max_stamina: float = 100.0
## ฟื้นต่อวินาที
@export var regen_per_second: float = 40.0
## หน่วงเวลาก่อนเริ่มฟื้น หลังใช้ Stamina (วินาที)
@export var regen_delay: float = 0.6

var current_stamina: float
var _regen_wait: float = 0.0


func _ready() -> void:
	current_stamina = max_stamina


func _physics_process(delta: float) -> void:
	if _regen_wait > 0.0:
		_regen_wait -= delta
		return
	if current_stamina < max_stamina:
		current_stamina = minf(current_stamina + regen_per_second * delta, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)


func has_enough(cost: float) -> bool:
	return current_stamina >= cost


## พยายามใช้ Stamina — คืนค่า true ถ้าพอและหักแล้ว, false ถ้าไม่พอ (ไม่หัก)
func try_spend(cost: float) -> bool:
	if current_stamina < cost:
		return false
	current_stamina -= cost
	_regen_wait = regen_delay
	stamina_changed.emit(current_stamina, max_stamina)
	return true
