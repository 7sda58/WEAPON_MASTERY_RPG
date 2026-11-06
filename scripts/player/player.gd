class_name Player
extends CharacterBody3D
## ตัวละครผู้เล่น — ภาพ Pixel (Sprite3D) ในโลก 3D, กล้องบุคคลที่ 3 หมุนด้วยเมาส์
## Task 2.3  — Movement: เดิน 8 ทิศ ตามทิศกล้อง (W = เดินไปทางที่กล้องมอง)
## Task 2.4  — Camera: เมาส์หมุนกล้องรอบตัว / ลูกกลิ้งซูม / Esc ปล่อยเมาส์
## Task 2.7 / 2.8 — HealthComponent และ StaminaComponent
## Task 2.9  — Basic Attack: นับเวลาเป็นเฟรม (60 เฟรม = 1 วินาที) ฟันไปทางที่กล้องมอง
## Task 2.11 — Dodge: พุ่งหลบพร้อม i-frame
## Task 2.13 — Input Buffer: กดปุ่มล่วงหน้าระหว่างท่าได้
## Task 2.14 — Perfect Dodge: หลบตรงจังหวะ → Stamina คืน + Slow-motion
## Task 2.15 — Parry: กดตรงจังหวะ → ไม่เสียเลือด ศัตรูเสียหลัก (ตีแรง ×2)

enum State { NORMAL, ATTACK, DODGE, PARRY, DEAD }

## ความเร็วเดิน (เมตรต่อวินาที)
@export var walk_speed: float = 4.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.0025
## มุมก้มกล้องสูงสุด/ต่ำสุด (องศา, ค่าลบ = มองลง)
@export var min_pitch_deg: float = -75.0
@export var max_pitch_deg: float = -8.0
@export var min_zoom: float = 3.0
@export var max_zoom: float = 12.0
@export var zoom_step: float = 0.6
## true = ฟันไปทางที่กล้องมอง | false = ฟันไปทางที่ตัวละครหันอยู่
@export var attack_toward_camera: bool = true

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
## ความเร็วตอนพุ่ง (เมตรต่อวินาที) — 14 เฟรม × 9 ≈ 2.1 เมตร
@export var dodge_speed: float = 9.0
@export var dodge_move_frames: int = 14
## หยุดนิ่งหลังพุ่ง ก่อนกลับมาขยับได้
@export var dodge_recovery: int = 6
## ช่วงอมตะ (เฟรมที่ iframe_start ถึง iframe_end)
@export var iframe_start: int = 2
@export var iframe_end: int = 11
@export var dodge_stamina_cost: float = 20.0

@export_group("Perfect Dodge")
## โดนตีภายในกี่เฟรมแรกของ i-frame ถึงนับเป็น Perfect (8 เฟรม ≈ 0.13 วินาที)
@export var perfect_dodge_frames: int = 8
## Stamina ที่ได้คืน (มากกว่าที่ใช้หลบ = ได้กำไร)
@export var perfect_dodge_refund: float = 25.0

@export_group("Parry (หน่วย: เฟรม)")
## หน้าต่าง Parry — กดแล้วมีผลกี่เฟรม (8 เฟรม ≈ 0.13 วินาที)
@export var parry_window: int = 8
## Parry พลาด (ไม่มีอะไรมาโดน) ต้องค้างท่านี้กี่เฟรม — ช่องให้ถูกลงโทษ
@export var parry_recovery: int = 20
@export var parry_stamina_cost: float = 10.0
@export var parry_stamina_refund: float = 20.0

@export_group("Slow-motion")
## ความเร็วเกมตอน Perfect Dodge / Parry (0.25 = ช้าลง 4 เท่า)
@export var slow_mo_scale: float = 0.25
## นานกี่วินาที (เวลาจริง)
@export var slow_mo_seconds: float = 0.3

@export_group("Input Buffer")
## จำปุ่มที่กดล่วงหน้าไว้กี่เฟรม (6 เฟรม = 0.1 วินาที)
@export var input_buffer_frames: int = 6

const TINT_NORMAL := Color(1, 1, 1, 1)
const TINT_STARTUP := Color(1, 1, 0.45, 1)
const TINT_RECOVERY := Color(0.55, 0.55, 0.6, 1)
const TINT_DEAD := Color(0.35, 0.35, 0.35, 1)
const TINT_PARRY := Color(0.6, 0.85, 1.6, 1)

var state: State = State.NORMAL
## ทิศที่ตัวละครหัน (แนวราบ, ความยาว 1)
var facing: Vector3 = Vector3.FORWARD
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _state_frame: int = 0
var _dodge_dir: Vector3 = Vector3.ZERO
## กันไม่ให้คลิกที่ใช้จับเมาส์กลับเข้าเกม กลายเป็นการฟัน
var _ignore_attack_frames: int = 0

var hurtbox: Hurtbox
var _buffered_action: StringName = &""
var _buffer_left: int = 0

@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent
@onready var hitbox: Hitbox = $Hitbox
@onready var body: Sprite3D = $Sprite3D
@onready var facing_arrow: Node3D = $FacingArrow
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D


func _ready() -> void:
	add_to_group("player")
	spring_arm.add_excluded_object(get_rid())  # กล้องไม่ชนตัวผู้เล่นเอง
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_create_hurtbox()


## สร้างพื้นที่รับดาเมจของผู้เล่น (Collision Layer 4 = ค่า 8) — Hitbox ของศัตรูจะมองหาชั้นนี้
func _create_hurtbox() -> void:
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 8
	hb.collision_mask = 0
	hb.health = health
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.7, 1.4, 0.7)
	shape.shape = box
	shape.position = Vector3(0, 0.7, 0)
	hb.add_child(shape)
	add_child(hb)
	hb.hit_received.connect(_on_hurtbox_hit)
	hb.parried.connect(_on_parried)
	hurtbox = hb


## ถูกโจมตี — ถ้าอยู่ในช่วง i-frame จะไม่เสียเลือด
## โดนในช่วงต้นของ i-frame = Perfect Dodge
func _on_hurtbox_hit(_hitbox: Hitbox) -> void:
	if not health.invincible:
		return
	var perfect_end: int = iframe_start + perfect_dodge_frames - 1
	if state == State.DODGE and _state_frame <= perfect_end:
		stamina.restore(perfect_dodge_refund)
		DamageNumber.spawn_text(get_tree().current_scene, global_position, "PERFECT!", Color(1.0, 0.85, 0.2))
		_slow_motion()
	else:
		DamageNumber.spawn_text(get_tree().current_scene, global_position, "DODGE!", Color(0.5, 0.9, 1.0))


## Parry สำเร็จ — ไม่เสียเลือด ได้ Stamina คืน และกลับมาขยับได้ทันทีเพื่อตีสวน
func _on_parried(_hitbox: Hitbox) -> void:
	hurtbox.parry_active = false
	stamina.restore(parry_stamina_refund)
	DamageNumber.spawn_text(get_tree().current_scene, global_position, "PARRY!", Color(1.0, 0.95, 0.4))
	body.modulate = TINT_NORMAL
	state = State.NORMAL
	_slow_motion()


## ทำให้เกมช้าลงชั่วครู่ — นับเวลาจริง ไม่ช้าตาม
func _slow_motion() -> void:
	Engine.time_scale = slow_mo_scale
	await get_tree().create_timer(slow_mo_seconds, true, false, true).timeout
	Engine.time_scale = 1.0


# ---------------- กล้องและเมาส์ ----------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x = clampf(spring_arm.rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = maxf(min_zoom, spring_arm.spring_length - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = minf(max_zoom, spring_arm.spring_length + zoom_step)
		elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # คลิกในเกม = จับเมาส์กลับ
			_ignore_attack_frames = 2
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Esc = ปล่อยเมาส์
	else:
		_debug_input(event)


## ทิศ "ไปข้างหน้า" ของกล้อง บนพื้นราบ
func _camera_forward() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, camera_pivot.global_rotation.y)


## แปลงปุ่ม WASD เป็นทิศบนพื้น ตามมุมกล้อง — ความยาวไม่เกิน 1 (แนวทแยงไม่เร็วกว่า)
func _get_move_dir() -> Vector3:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera_pivot.global_rotation.y)


# ---------------- ลูปหลัก ----------------
func _physics_process(delta: float) -> void:
	_update_input_buffer()
	match state:
		State.NORMAL:
			_state_normal()
		State.ATTACK:
			_state_attack()
		State.DODGE:
			_state_dodge()
		State.PARRY:
			_state_parry()
		State.DEAD:
			_set_horizontal(Vector3.ZERO)
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	_update_facing_visual()


func _set_horizontal(v: Vector3) -> void:
	velocity.x = v.x
	velocity.z = v.z


## หมุนลูกศรใต้เท้าและ Hitbox ไปตามทิศที่หัน
func _update_facing_visual() -> void:
	var yaw: float = atan2(-facing.x, -facing.z)
	facing_arrow.rotation.y = yaw
	hitbox.rotation.y = yaw


# ---------------- INPUT BUFFER ----------------
func _update_input_buffer() -> void:
	if _ignore_attack_frames > 0:
		_ignore_attack_frames -= 1
	for action: StringName in [&"attack", &"dodge", &"parry"]:
		if Input.is_action_just_pressed(action) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if action == &"attack" and _ignore_attack_frames > 0:
				continue
			_buffered_action = action
			_buffer_left = input_buffer_frames
	if _buffer_left > 0:
		_buffer_left -= 1
		if _buffer_left == 0:
			_buffered_action = &""


func _consume_buffer(action: StringName) -> bool:
	if _buffered_action == action and _buffer_left > 0:
		_buffered_action = &""
		_buffer_left = 0
		return true
	return false


# ---------------- NORMAL: ยืน / เดิน ----------------
func _state_normal() -> void:
	var move_dir: Vector3 = _get_move_dir()

	if _consume_buffer(&"dodge"):
		if stamina.try_spend(dodge_stamina_cost):
			_start_dodge(move_dir)
			return
		print("Stamina ไม่พอสำหรับหลบ")

	if _consume_buffer(&"parry"):
		if stamina.try_spend(parry_stamina_cost):
			_start_parry()
			return
		print("Stamina ไม่พอสำหรับ Parry")

	if _consume_buffer(&"attack"):
		if stamina.try_spend(attack_stamina_cost):
			_start_attack()
			return
		print("Stamina ไม่พอสำหรับโจมตี")

	_set_horizontal(move_dir * walk_speed)
	if move_dir.length() > 0.05:
		facing = move_dir.normalized()


# ---------------- ATTACK: Startup → Active → Recovery ----------------
func _start_attack() -> void:
	state = State.ATTACK
	_state_frame = 0
	_set_horizontal(Vector3.ZERO)
	if attack_toward_camera:
		facing = _camera_forward()  # หันไปทางที่กล้องมองก่อนฟัน
	hitbox.damage = attack_damage
	_update_facing_visual()


func _state_attack() -> void:
	_state_frame += 1
	_set_horizontal(Vector3.ZERO)

	var active_start: int = attack_startup + 1
	var active_end: int = attack_startup + attack_active + 1
	var total: int = attack_startup + attack_active + attack_recovery

	if _state_frame < active_start:
		body.modulate = TINT_STARTUP        # Startup: ตัวออกเหลือง
	elif _state_frame == active_start:
		body.modulate = TINT_NORMAL
		hitbox.activate()                   # Active: เปิด Hitbox
	elif _state_frame == active_end:
		hitbox.deactivate()
		body.modulate = TINT_RECOVERY       # Recovery: ตัวออกเข้ม

	if _state_frame >= total:
		body.modulate = TINT_NORMAL
		state = State.NORMAL


# ---------------- DODGE: พุ่ง (มี i-frame) → Recovery ----------------
func _start_dodge(move_dir: Vector3) -> void:
	state = State.DODGE
	_state_frame = 0
	# หลบไปทางที่กดเดินอยู่ — ถ้ายืนนิ่งให้ถอยหลังจากทิศที่หัน
	_dodge_dir = move_dir.normalized() if move_dir.length() > 0.05 else -facing


func _state_dodge() -> void:
	_state_frame += 1

	var invincible: bool = _state_frame >= iframe_start and _state_frame <= iframe_end
	health.invincible = invincible
	body.modulate = Color(1, 1, 1, 0.4) if invincible else TINT_NORMAL

	if _state_frame <= dodge_move_frames:
		_set_horizontal(_dodge_dir * dodge_speed)
	else:
		_set_horizontal(Vector3.ZERO)
		body.modulate = TINT_RECOVERY

	if _state_frame >= dodge_move_frames + dodge_recovery:
		_end_dodge()
		state = State.NORMAL


func _end_dodge() -> void:
	health.invincible = false
	body.modulate = TINT_NORMAL


# ---------------- PARRY: หน้าต่าง Parry → (พลาด) Recovery ----------------
func _start_parry() -> void:
	state = State.PARRY
	_state_frame = 0
	_set_horizontal(Vector3.ZERO)
	if attack_toward_camera:
		facing = _camera_forward()
	hurtbox.parry_active = true


func _state_parry() -> void:
	_state_frame += 1
	_set_horizontal(Vector3.ZERO)
	if _state_frame <= parry_window:
		body.modulate = TINT_PARRY          # หน้าต่าง Parry: ตัวเรืองฟ้า
	else:
		hurtbox.parry_active = false
		body.modulate = TINT_RECOVERY       # พลาด: ค้างท่า โดนตีได้
	if _state_frame >= parry_window + parry_recovery:
		body.modulate = TINT_NORMAL
		state = State.NORMAL


# ---------------- โดนตี / ตาย ----------------
func _on_health_changed(current: int, maximum: int) -> void:
	print("Player HP: %d / %d" % [current, maximum])


func _on_damaged(amount: int) -> void:
	DamageNumber.spawn(get_tree().current_scene, global_position, amount, Color(1, 0.4, 0.4))


func _on_died() -> void:
	print("Player died")
	_end_dodge()
	if hurtbox:
		hurtbox.parry_active = false
	state = State.DEAD
	hitbox.deactivate()
	body.modulate = TINT_DEAD  # ชั่วคราว จนกว่าจะมีระบบตายจริง


# ---------------- DEBUG (ปุ่มทดสอบ — จะลบเมื่อปิด Phase 2) ----------------
# F1 = โดนดาเมจ 15 | F2 = ใช้ Stamina 30 | F3 = ฟื้น HP เต็ม
# F4 = เปิด/ปิด "ดาเมจอัตโนมัติทุก 1 วินาที" ไว้ฝึกจับจังหวะหลบ
var _debug_pulse: Timer


func _debug_input(event: InputEvent) -> void:
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
				body.modulate = TINT_NORMAL
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
