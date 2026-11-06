class_name Player
extends CharacterBody2D
## ตัวละครผู้เล่น
## Task 2.3  — Movement: เดิน 8 ทิศ ความเร็วแนวทแยงเท่าแนวตรง
## Task 2.7 / 2.8 — HealthComponent และ StaminaComponent
## Task 2.9  — Basic Attack: นับเวลาเป็นเฟรม (60 เฟรม = 1 วินาที) / เล็งด้วยเมาส์ (Task 1.2)
## Task 2.11 — Dodge: พุ่งหลบพร้อม i-frame (ช่วงอมตะ)
## Task 2.13 — Input Buffer: กดปุ่มล่วงหน้าระหว่างท่าได้ ท่าถัดไปจะออกทันทีที่ว่าง

enum State { NORMAL, ATTACK, DODGE, DEAD }

## ความเร็วเดิน (พิกเซลต่อวินาที)
@export var walk_speed: float = 90.0

@export_group("Aim")
## true = โจมตีไปทางเมาส์ | false = โจมตีไปทางที่เดินอยู่
@export var aim_with_mouse: bool = true
## true = ล็อกทิศโจมตีเป็น 8 ทิศ | false = เล็งได้ทุกองศา
@export var snap_aim_8_directions: bool = false

@export_group("Basic Attack (หน่วย: เฟรม)")
## ช่วงง้าง — ยังไม่โดน
@export var attack_startup: int = 6
## ช่วงที่ Hitbox เปิด — โดนได้
@export var attack_active: int = 4
## ช่วงฟื้นตัว — ขยับไม่ได้ เปิดช่องให้ถูกสวน
@export var attack_recovery: int = 12
@export var attack_damage: int = 10
@export var attack_stamina_cost: float = 15.0

@export_group("Dodge (หน่วย: เฟรม)")
## ความเร็วตอนพุ่ง (พิกเซลต่อวินาที)
@export var dodge_speed: float = 210.0
## จำนวนเฟรมที่พุ่ง — 14 เฟรม × 210 ≈ 49 พิกเซล
@export var dodge_move_frames: int = 14
## หยุดนิ่งหลังพุ่ง ก่อนกลับมาขยับได้
@export var dodge_recovery: int = 6
## เฟรมแรกที่อมตะ
@export var iframe_start: int = 2
## เฟรมสุดท้ายที่อมตะ — i-frame ยาว 10 เฟรม (≈0.17 วินาที)
@export var iframe_end: int = 11
@export var dodge_stamina_cost: float = 20.0

@export_group("Input Buffer")
## จำปุ่มที่กดล่วงหน้าไว้กี่เฟรม (6 เฟรม = 0.1 วินาที)
@export var input_buffer_frames: int = 6

var state: State = State.NORMAL
## ทิศที่ตัวละครหันอยู่ — ใช้กำหนดทิศโจมตี
var facing: Vector2 = Vector2.DOWN
var _state_frame: int = 0
var _dodge_dir: Vector2 = Vector2.ZERO
var _base_color: Color

## Input Buffer — ปุ่มล่าสุดที่กดและเวลาที่เหลือ
var _buffered_action: StringName = &""
var _buffer_left: int = 0

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
	_update_input_buffer()
	match state:
		State.NORMAL:
			_state_normal()
		State.ATTACK:
			_state_attack()
		State.DODGE:
			_state_dodge()
		State.DEAD:
			velocity = Vector2.ZERO
	move_and_slide()


# ---------------- INPUT BUFFER ----------------
func _update_input_buffer() -> void:
	for action: StringName in [&"attack", &"dodge"]:
		if Input.is_action_just_pressed(action):
			_buffered_action = action
			_buffer_left = input_buffer_frames
	if _buffer_left > 0:
		_buffer_left -= 1
		if _buffer_left == 0:
			_buffered_action = &""


## ดึงปุ่มที่จำไว้ออกมาใช้ (ใช้แล้วล้างทิ้ง)
func _consume_buffer(action: StringName) -> bool:
	if _buffered_action == action and _buffer_left > 0:
		_buffered_action = &""
		_buffer_left = 0
		return true
	return false


# ---------------- NORMAL: ยืน / เดิน ----------------
func _state_normal() -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _consume_buffer(&"dodge"):
		if stamina.try_spend(dodge_stamina_cost):
			_start_dodge(input_dir)
			return
		print("Stamina ไม่พอสำหรับหลบ")

	if _consume_buffer(&"attack"):
		if stamina.try_spend(attack_stamina_cost):
			_start_attack()
			return
		print("Stamina ไม่พอสำหรับโจมตี")

	# get_vector จำกัดความยาวไม่เกิน 1 — เดินแนวทแยงไม่เร็วกว่าแนวตรง
	velocity = input_dir * walk_speed
	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()


# ---------------- ATTACK: Startup → Active → Recovery ----------------
func _start_attack() -> void:
	state = State.ATTACK
	_state_frame = 0
	velocity = Vector2.ZERO
	if aim_with_mouse:
		facing = _get_mouse_direction()  # หันตัวไปทางเมาส์ก่อนฟัน
	hitbox.damage = attack_damage
	hitbox.rotation = facing.angle()  # หมุน Hitbox ไปทางที่หันอยู่


## ทิศจากตัวละครไปยังเมาส์ (วัดจากจุดกลางลำตัว ไม่ใช่เท้า)
func _get_mouse_direction() -> Vector2:
	var dir: Vector2 = get_global_mouse_position() - hitbox.global_position
	if dir.length() < 1.0:
		return facing  # เมาส์อยู่บนตัวพอดี — ใช้ทิศเดิม
	if snap_aim_8_directions:
		dir = Vector2.RIGHT.rotated(snappedf(dir.angle(), PI / 4.0))
	return dir.normalized()


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


# ---------------- DODGE: พุ่ง (มี i-frame) → Recovery ----------------
func _start_dodge(input_dir: Vector2) -> void:
	state = State.DODGE
	_state_frame = 0
	# หลบไปทางที่กดเดินอยู่ — ถ้ายืนนิ่งให้ถอยหลังจากทิศที่หัน
	_dodge_dir = input_dir.normalized() if input_dir != Vector2.ZERO else -facing


func _state_dodge() -> void:
	_state_frame += 1

	# i-frame: อมตะเฉพาะช่วงที่กำหนด — ตัวโปร่งให้เห็น
	var invincible: bool = _state_frame >= iframe_start and _state_frame <= iframe_end
	health.invincible = invincible
	body.modulate.a = 0.35 if invincible else 1.0

	if _state_frame <= dodge_move_frames:
		velocity = _dodge_dir * dodge_speed
	else:
		velocity = Vector2.ZERO
		body.color = _base_color.darkened(0.4)            # Recovery: ตัวออกเข้ม

	if _state_frame >= dodge_move_frames + dodge_recovery:
		_end_dodge()
		state = State.NORMAL


func _end_dodge() -> void:
	health.invincible = false
	body.modulate.a = 1.0
	body.color = _base_color


# ---------------- โดนตี / ตาย ----------------
func _on_health_changed(current: int, maximum: int) -> void:
	print("Player HP: %d / %d" % [current, maximum])


func _on_damaged(amount: int) -> void:
	DamageNumber.spawn(get_tree().current_scene, global_position, amount, Color(1, 0.4, 0.4))


func _on_died() -> void:
	print("Player died")
	_end_dodge()
	state = State.DEAD
	hitbox.deactivate()
	body.color = Color(0.4, 0.4, 0.4)  # ชั่วคราว จนกว่าจะมีระบบตายจริงในข้อ 23


# ---------------- DEBUG (ลบออกเมื่อมีศัตรูตีกลับและ HUD) ----------------
# F1 = โดนดาเมจ 15 | F2 = ใช้ Stamina 30 | F3 = ฟื้น HP เต็ม
# F4 = เปิด/ปิด "ดาเมจอัตโนมัติทุก 1 วินาที" ไว้ฝึกจับจังหวะหลบ
var _debug_pulse: Timer


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				_debug_hit(15)
			KEY_F2:
				if not stamina.try_spend(30):
					print("Stamina ไม่พอ!")
			KEY_F3:
				health.reset()
				state = State.NORMAL
				body.color = _base_color
			KEY_F4:
				_toggle_debug_pulse()


func _debug_hit(amount: int) -> void:
	if health.invincible:
		DamageNumber.spawn_text(get_tree().current_scene, global_position, "DODGE!", Color(0.5, 0.9, 1.0))
		return
	health.take_damage(amount)


func _toggle_debug_pulse() -> void:
	if _debug_pulse == null:
		_debug_pulse = Timer.new()
		_debug_pulse.wait_time = 1.0
		_debug_pulse.timeout.connect(func() -> void: _debug_hit(5))
		add_child(_debug_pulse)
	if _debug_pulse.is_stopped():
		_debug_pulse.start()
		print("ดาเมจอัตโนมัติ: เปิด (ทุก 1 วินาที)")
	else:
		_debug_pulse.stop()
		print("ดาเมจอัตโนมัติ: ปิด")
