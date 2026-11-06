class_name Player
extends CharacterBody2D
## ตัวละครผู้เล่น
## Task 2.3 — Movement System: เดิน 8 ทิศ ความเร็วแนวทแยงเท่าแนวตรง
## Task 2.7 / 2.8 — เชื่อม HealthComponent และ StaminaComponent

## ความเร็วเดิน (พิกเซลต่อวินาที) — จอกว้าง 480 px เดินข้ามจอประมาณ 5 วินาที
@export var walk_speed: float = 90.0

## ทิศที่ตัวละครหันอยู่ — ใช้ต่อในระบบโจมตีและ Animation
var facing: Vector2 = Vector2.DOWN

@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	stamina.stamina_changed.connect(_on_stamina_changed)


func _physics_process(_delta: float) -> void:
	if health.is_dead:
		velocity = Vector2.ZERO
		return

	# รวมปุ่ม 4 ทิศเป็นเวกเตอร์เดียว — get_vector จำกัดความยาวไม่เกิน 1 ให้อัตโนมัติ
	# ทำให้เดินแนวทแยงไม่เร็วกว่าแนวตรง
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = input_dir * walk_speed

	# จำทิศล่าสุดไว้ แม้หยุดเดินแล้วก็ยังหันทางเดิม
	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()

	# เคลื่อนที่และไถลไปตามกำแพงเมื่อชน (Task 2.5)
	move_and_slide()


func _on_health_changed(current: int, maximum: int) -> void:
	print("Player HP: %d / %d" % [current, maximum])


func _on_stamina_changed(current: float, maximum: float) -> void:
	print("Player Stamina: %d / %d" % [current, maximum])


func _on_died() -> void:
	print("Player died")
	$ColorRect.color = Color(0.4, 0.4, 0.4)  # ตัวเทาเมื่อตาย (ชั่วคราว จนกว่าจะมีระบบตายจริงในข้อ 23)


# ---------------- DEBUG (ลบออกเมื่อมีระบบโจมตีและ HUD) ----------------
# F1 = โดนดาเมจ 15 | F2 = ใช้ Stamina 30 | F3 = ฟื้น HP เต็ม
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				health.take_damage(15)
			KEY_F2:
				if not stamina.try_spend(30):
					print("Stamina ไม่พอ!")
			KEY_F3:
				health.reset()
				$ColorRect.color = Color(0.086, 1, 0.235)
