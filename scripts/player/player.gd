class_name Player
extends CharacterBody2D
## ตัวละครผู้เล่น
## Task 2.3 — Movement System: เดิน 8 ทิศ ความเร็วแนวทแยงเท่าแนวตรง

## ความเร็วเดิน (พิกเซลต่อวินาที) — จอกว้าง 480 px เดินข้ามจอประมาณ 5 วินาที
@export var walk_speed: float = 90.0

## ทิศที่ตัวละครหันอยู่ — ใช้ต่อในระบบโจมตีและ Animation
var facing: Vector2 = Vector2.DOWN


func _physics_process(_delta: float) -> void:
	# รวมปุ่ม 4 ทิศเป็นเวกเตอร์เดียว — get_vector จำกัดความยาวไม่เกิน 1 ให้อัตโนมัติ
	# ทำให้เดินแนวทแยงไม่เร็วกว่าแนวตรง
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = input_dir * walk_speed

	# จำทิศล่าสุดไว้ แม้หยุดเดินแล้วก็ยังหันทางเดิม
	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()

	# เคลื่อนที่และไถลไปตามกำแพงเมื่อชน (Task 2.5)
	move_and_slide()
