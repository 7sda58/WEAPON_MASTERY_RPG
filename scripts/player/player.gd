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
## Task 2.12 — Combat Feedback: รอยดาบ / กล้องสั่น / โดนตีแล้วกระเด็นและชะงัก (Hitstop + ประกายไฟอยู่ใน hitbox.gd)
## ตาย → หน้าจอ YOU DIED → กด R เกิดใหม่ที่จุดเริ่ม (ศัตรูรีเซ็ตด้วย)
## Task 3.1 — ค่าท่าโจมตีอ่านจาก WeaponData (data/weapons/*.tres) + โมเดลอาวุธที่ถือและท่าฟัน

enum State { NORMAL, ATTACK, DODGE, PARRY, HITSTUN, DEAD }

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

@export_group("Weapon")
## อาวุธที่ถืออยู่ — ค่าเฟรม ดาเมจ ระยะ อยู่ในไฟล์นี้ (แก้ที่ data/weapons/sword.tres)
@export var weapon: WeaponData = preload("res://data/weapons/sword.tres")

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

@export_group("Hit Reaction (โดนตี)")
## ชะงักกี่เฟรมเมื่อโดนตี (ขยับ/โจมตีไม่ได้)
@export var hitstun_frames: int = 16
## ความเร็วกระเด็นตอนโดนตี (เมตรต่อวินาที)
@export var knockback_speed: float = 6.0

@export_group("Camera Shake")
## สั่นเมื่อเราตีโดน
@export var shake_on_hit: float = 0.06
## สั่นเมื่อเราโดนตี (แรงกว่า)
@export var shake_on_hurt: float = 0.16
## สั่นเมื่อ Parry สำเร็จ
@export var shake_on_parry: float = 0.1
## ลดแรงสั่นต่อวินาที
@export var shake_decay: float = 0.9

@export_group("Input Buffer")
## จำปุ่มที่กดล่วงหน้าไว้กี่เฟรม (6 เฟรม = 0.1 วินาที)
@export var input_buffer_frames: int = 6

const TINT_NORMAL := Color(1, 1, 1, 1)
const TINT_STARTUP := Color(1, 1, 0.45, 1)
const TINT_RECOVERY := Color(0.55, 0.55, 0.6, 1)
const TINT_DEAD := Color(0.35, 0.35, 0.35, 1)
const TINT_PARRY := Color(0.6, 0.85, 1.6, 1)
const DEATH_SCREEN := preload("res://scenes/ui/death_screen.tscn")

var state: State = State.NORMAL
## ทิศที่ตัวละครหัน (แนวราบ, ความยาว 1)
var facing: Vector3 = Vector3.FORWARD
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _state_frame: int = 0
var _dodge_dir: Vector3 = Vector3.ZERO
## กันไม่ให้คลิกที่ใช้จับเมาส์กลับเข้าเกม กลายเป็นการฟัน
var _ignore_attack_frames: int = 0

var hurtbox: Hurtbox
var _shake: float = 0.0
var _spawn_pos: Vector3
## โครงสำหรับถืออาวุธ: WeaponRoot (หันตามตัวละคร) → SwingPivot (ท่าฟัน) → โมเดล
var _weapon_root: Node3D
var _swing_pivot: Node3D
var _weapon_model: Node3D

## ท่าถือดาบ (องศา): yaw = กวาดซ้าย-ขวา, pitch = ก้ม-เงย
const POSE_IDLE := Vector2(-55.0, -55.0)      # ถือข้างตัวด้านขวา ปลายชี้ลงหน้า
const POSE_SWING_PITCH := -8.0                # ตอนฟัน ใบดาบเกือบขนานพื้น
const POSE_PARRY := Vector2(-15.0, 35.0)      # ยกดาบขึ้นตั้งรับด้านหน้า
var _death_screen: CanvasLayer
var _buffered_action: StringName = &""
var _buffer_left: int = 0

@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent
@onready var hitbox: Hitbox = $Hitbox
@onready var body: Sprite3D = $Sprite3D
@onready var facing_arrow: Node3D = $FacingArrow
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D


func _ready() -> void:
	add_to_group("player")
	_spawn_pos = global_position
	_death_screen = DEATH_SCREEN.instantiate()
	add_child(_death_screen)
	_death_screen.respawn_requested.connect(respawn)
	spring_arm.add_excluded_object(get_rid())  # กล้องไม่ชนตัวผู้เล่นเอง
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hitbox.hit_landed.connect(func(_h: Hurtbox) -> void: shake(shake_on_hit))
	_create_hurtbox()
	_create_weapon_rig()
	equip(weapon)


func _create_weapon_rig() -> void:
	_weapon_root = Node3D.new()
	_weapon_root.name = "WeaponRoot"
	_weapon_root.position = Vector3(0, 0.75, 0)   # ระดับอก
	add_child(_weapon_root)
	_swing_pivot = Node3D.new()
	_swing_pivot.name = "SwingPivot"
	_weapon_root.add_child(_swing_pivot)


## ถืออาวุธ — ปรับขนาดและระยะ Hitbox ตามข้อมูลอาวุธ
func equip(data: WeaponData) -> void:
	weapon = data
	var shape_node := $Hitbox/CollisionShape3D as CollisionShape3D
	var box := BoxShape3D.new()
	box.size = data.hitbox_size
	shape_node.shape = box
	shape_node.position = Vector3(0, 0.75, -data.reach)
	hitbox.damage = data.damage
	hitbox.hitstop_seconds = data.hitstop_seconds
	# เปลี่ยนโมเดลอาวุธ
	if _weapon_model:
		_weapon_model.queue_free()
		_weapon_model = null
	if data.model_scene:
		_weapon_model = data.model_scene.instantiate()
		_swing_pivot.add_child(_weapon_model)
		_weapon_model.position = Vector3(0, 0, -0.22)   # มือห่างจากกลางตัว
	_set_pose(POSE_IDLE.x, POSE_IDLE.y)


func _set_pose(yaw_deg: float, pitch_deg: float) -> void:
	_swing_pivot.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)


## ท่าถืออาวุธตามสถานะ — เรียกทุกเฟรม (Hitstop ทำให้ดาบค้างกลางท่าเองโดยอัตโนมัติ)
func _update_weapon_pose() -> void:
	if _weapon_model == null:
		return
	_weapon_model.visible = state != State.DEAD
	match state:
		State.ATTACK:
			var s: int = weapon.startup_frames
			var a: int = weapon.active_frames
			var r: int = weapon.recovery_frames
			var f: int = _state_frame
			if f <= s:
				# ง้าง: เหวี่ยงไปทางขวา-หลัง และยกใบดาบขึ้น
				var t: float = ease(float(f) / s, 0.5)
				_set_pose(lerpf(POSE_IDLE.x, weapon.windup_angle, t), lerpf(POSE_IDLE.y, POSE_SWING_PITCH, t))
			elif f <= s + a:
				# ฟัน: กวาดผ่านหน้าตัวไปทางซ้ายอย่างรวดเร็ว
				var t: float = float(f - s) / a
				_set_pose(lerpf(weapon.windup_angle, weapon.swing_end_angle, t), POSE_SWING_PITCH)
			else:
				# ฟื้นตัว: ค่อย ๆ กลับมาท่าถือ
				var t: float = ease(float(f - s - a) / r, 2.0)
				_set_pose(lerpf(weapon.swing_end_angle, POSE_IDLE.x, t), lerpf(POSE_SWING_PITCH, POSE_IDLE.y, t))
		State.PARRY:
			_set_pose(POSE_PARRY.x, POSE_PARRY.y)
		_:
			_set_pose(POSE_IDLE.x, POSE_IDLE.y)


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
func _on_hurtbox_hit(attacker: Hitbox) -> void:
	if not health.invincible:
		_take_hit(attacker)
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
	shake(shake_on_parry)
	HitSpark.spawn(get_tree().current_scene, hurtbox.get_center() + facing * 0.4, Color(0.7, 0.9, 1.0), 24)
	_slow_motion()


## ทำให้เกมช้าลงชั่วครู่ (Perfect Dodge / Parry)
func _slow_motion() -> void:
	HitStop.apply(slow_mo_scale, slow_mo_seconds)


## โดนตีจริง — ยกเลิกท่าที่ทำอยู่ กระเด็นออกจากผู้โจมตี และชะงัก
func _take_hit(attacker: Hitbox) -> void:
	shake(shake_on_hurt)
	if health.is_dead:
		return
	hitbox.deactivate()
	hurtbox.parry_active = false
	var away: Vector3 = global_position - attacker.global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = -facing
	_set_horizontal(away.normalized() * knockback_speed)
	state = State.HITSTUN
	_state_frame = 0


func _state_hitstun() -> void:
	_state_frame += 1
	velocity.x = move_toward(velocity.x, 0.0, 0.6)
	velocity.z = move_toward(velocity.z, 0.0, 0.6)
	# กระพริบแดง-ขาว
	body.modulate = Color(2.0, 0.6, 0.6) if (_state_frame / 3) % 2 == 0 else TINT_NORMAL
	if _state_frame >= hitstun_frames:
		body.modulate = TINT_NORMAL
		state = State.NORMAL


# ---------------- กล้องสั่น ----------------
## สั่งให้กล้องสั่น — ค่าใหม่แรงกว่าค่าที่สั่นอยู่ถึงจะแทนที่
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	if _shake > 0.0:
		camera.h_offset = randf_range(-1.0, 1.0) * _shake
		camera.v_offset = randf_range(-1.0, 1.0) * _shake
		_shake = move_toward(_shake, 0.0, shake_decay * delta)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


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
		State.HITSTUN:
			_state_hitstun()
		State.DEAD:
			_set_horizontal(Vector3.ZERO)
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	_update_facing_visual()
	_update_weapon_pose()


func _set_horizontal(v: Vector3) -> void:
	velocity.x = v.x
	velocity.z = v.z


## หมุนลูกศรใต้เท้าและ Hitbox ไปตามทิศที่หัน
func _update_facing_visual() -> void:
	var yaw: float = atan2(-facing.x, -facing.z)
	facing_arrow.rotation.y = yaw
	hitbox.rotation.y = yaw
	if _weapon_root:
		_weapon_root.rotation.y = yaw


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
		if stamina.try_spend(weapon.stamina_cost):
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
	hitbox.damage = weapon.damage
	_update_facing_visual()


func _state_attack() -> void:
	_state_frame += 1
	_set_horizontal(Vector3.ZERO)

	var active_start: int = weapon.startup_frames + 1
	var active_end: int = weapon.startup_frames + weapon.active_frames + 1
	var total: int = weapon.total_frames()

	if _state_frame < active_start:
		body.modulate = TINT_STARTUP        # Startup: ตัวออกเหลือง
	elif _state_frame == active_start:
		body.modulate = TINT_NORMAL
		hitbox.activate()                   # Active: เปิด Hitbox
		SlashEffect.spawn(self, Vector3(0, 0.8, 0), atan2(-facing.x, -facing.z) - 0.25, weapon.slash_color)
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
	_end_dodge()
	if hurtbox:
		hurtbox.parry_active = false
	state = State.DEAD
	hitbox.deactivate()
	_set_horizontal(Vector3.ZERO)
	HitStop.apply(0.3, 0.7)                 # ช้าลงตอนล้ม ให้รู้ว่าตายแล้ว
	# ล้มลง: ยุบตัว จมลงพื้น สีเทา
	var t := create_tween().set_parallel(true)
	t.tween_property(body, "modulate", TINT_DEAD, 0.4)
	t.tween_property(body, "scale", Vector3(1.25, 0.35, 1.0), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(body, "position:y", 0.3, 0.35)
	await get_tree().create_timer(0.6, true, false, true).timeout
	if state == State.DEAD:
		_death_screen.show_death()


## เกิดใหม่ที่จุดเริ่ม — HP/Stamina เต็ม และรีเซ็ตศัตรูทั้งหมด
func respawn() -> void:
	Engine.time_scale = 1.0
	_death_screen.hide_death()
	global_position = _spawn_pos
	velocity = Vector3.ZERO
	health.reset()
	stamina.restore(stamina.max_stamina)
	body.modulate = TINT_NORMAL
	body.scale = Vector3.ONE
	body.position.y = 0.75
	state = State.NORMAL
	_state_frame = 0
	_buffered_action = &""
	get_tree().call_group("enemies", "reset_enemy")
