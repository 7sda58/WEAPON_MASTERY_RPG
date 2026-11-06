class_name Player
extends CharacterBody2D
## ตัวละครผู้เล่น
## Task 2.3 — Movement: เดิน 8 ทิศ ความเร็วแนวทแยงเท่าแนวตรง
## Task 2.7 / 2.8 — HealthComponent และ StaminaComponent
## Task 2.9 — Basic Attack: นับเวลาเป็นเฟรม (60 เฟรม = 1 วินาที)

enum State { NORMAL, ATTACK, DEAD }

## ความเร็วเดิน (พิกเซลต่อวินาที)
@export var walk_speed: float = 90.0

@export_group("Basic Attack (หน่วย: เฟรม)")
## ช่วงง้าง — ยังไม่โดน
@export var attack_startup: int = 6
## ช่วงที่ Hitbox เปิด — โดนได้
@export var attack_active: int = 4
## ช่วงฟื้นตัว — ขยับไม่ได้ เปิดช่องให้ถูกสวน
@export var attack_recovery: int = 12
@export var attack_damage: int = 10
@export var attack_stamina_cost: float = 15.0

var state: State = State.NORMAL
## ทิศที่ตัวละครหันอยู่ — ใช้กำหนดทิศโจมตี
var facing: Vector2 = Vector2.DOWN
var _state_frame: int = 0
var _base_color: Color

@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent
@onready var hitbox: Hitbox = $Hitbox
@onready var body: ColorRect = $ColorRect


func _ready() -> void:
	add_to_group("player")
	_base_color = body.color
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _physics_process(_delta: float) -> void:
	match state:
		State.NORMAL:
			_state_normal()
		State.ATTACK:
			_state_attack()
		State.DEAD:
			velocity = Vector2.ZERO
	move_and_slide()


# ---------------- NORMAL: ยืน / เดิน ----------------
func _state_normal() -> void:
	if Input.is_action_just_pressed("attack"):
		if stamina.try_spend(attack_stamina_cost):
			_start_attack()
			return
		print("Stamina ไม่พอสำหรับโจมตี")

	# get_vector จำกัดความยาวไม่เกิน 1 — เดินแนวทแยงไม่เร็วกว่าแนวตรง
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * walk_speed
	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()


# ---------------- ATTACK: Startup → Active → Recovery ----------------
func _start_attack() -> void:
	state = State.ATTACK
	_state_frame = 0
	velocity = Vector2.ZERO
	hitbox.damage = attack_damage
	hitbox.rotation = facing.angle()  # หมุน Hitbox ไปทางที่หันอยู่


func _state_attack() -> void:
	_state_frame += 1
	velocity = Vector2.ZERO

	var active_start: int = attack_startup + 1
	var active_end: int = attack_startup + attack_active + 1
	var total: int = attack_startup + attack_active + attack_recovery

	if _state_frame < active_start:
		body.color = _base_color.lerp(Color.YELLOW, 0.6)   # Startup: ตัวออกเหลือง
	elif _state_frame == active_start:
		body.color = _base_color
		hitbox.activate()                                  # Active: เปิด Hitbox
	elif _state_frame == active_end:
		hitbox.deactivate()
		body.color = _base_color.darkened(0.4)            # Recovery: ตัวออกเข้ม

	if _state_frame >= total:
		body.color = _base_color
		state = State.NORMAL


# ---------------- ตาย ----------------
func _on_health_changed(current: int, maximum: int) -> void:
	print("Player HP: %d / %d" % [current, maximum])


func _on_damaged(amount: int) -> void:
	DamageNumber.spawn(get_tree().current_scene, global_position, amount, Color(1, 0.4, 0.4))


func _on_died() -> void:
	print("Player died")
	state = State.DEAD
	hitbox.deactivate()
	body.color = Color(0.4, 0.4, 0.4)  # ชั่วคราว จนกว่าจะมีระบบตายจริงในข้อ 23


# ---------------- DEBUG (ลบออกเมื่อมีศัตรูตีกลับและ HUD) ----------------
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
				state = State.NORMAL
				body.color = _base_color
