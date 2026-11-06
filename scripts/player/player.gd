class_name Player
extends CharacterBody3D
## ตัวละครผู้เล่น — โมเดล 3D Low-poly ในโลก 3D, กล้องบุคคลที่ 3 หมุนด้วยเมาส์
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
## Task 3.1 — อาวุธอ่านจาก WeaponData (data/weapons/*.tres) + โมเดลอาวุธที่ถือ
## Task 2.6 — โมเดล 3D Low-poly (PlayerModel): เดิน/เอนตัว/บิดตัว และมือจับอาวุธตามท่าของอาวุธแต่ละชนิด (CR-014)
## Task 3.6 — เปลี่ยนอาวุธ: ปุ่ม 1 = ดาบ, 2 = หอก (ชั่วคราว จนกว่าจะมี Input Map)
## Task 3.8–3.9 — Weapon Mastery: EXP/เลเวลแยกตามอาวุธ (MasteryComponent)
## Task 3.7 — ท่าโจมตีเป็นคอมโบ (AttackMove): ฟัน/ปัด หรือ แทง แต่ละท่ามี Hitbox และเอฟเฟกต์ของตัวเอง

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
## อาวุธที่ถืออยู่ — ท่าโจมตี ดาเมจ ระยะ อยู่ในไฟล์ .tres (data/weapons/)
@export var weapon: WeaponData = preload("res://data/weapons/sword.tres")
## อาวุธที่สลับได้ด้วยปุ่มตัวเลข (ลำดับ = ปุ่ม 1, 2, ...)
@export var weapon_slots: Array[WeaponData] = [
	preload("res://data/weapons/sword.tres"),
	preload("res://data/weapons/spear.tres"),
]

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
var mastery: MasteryComponent
var _shake: float = 0.0
var _spawn_pos: Vector3
## โครงสำหรับถืออาวุธ: WeaponRoot (หันตามตัวละคร) → SwingPivot (ท่าฟัน) → โมเดล
var _weapon_root: Node3D
var _swing_pivot: Node3D
var _weapon_model: Node3D

## มุมกวาดอาวุธล่าสุด (องศา) — ใช้บิดลำตัวตาม
var _swing_yaw_deg: float = 0.0
var _hitbox_box: BoxShape3D
var _hitbox_shape: CollisionShape3D

## คอมโบ: ท่าที่กำลังเล่น / ท่าถัดไป / กดต่อคอมโบไว้แล้วหรือยัง
var _move: AttackMove
var _move_index: int = 0
var _combo_index: int = 0
var _combo_queued: bool = false
var _frames_since_attack: int = 999

## ท่าถือ (องศา): x = หันซ้าย-ขวา, y = ก้ม-เงย
const POSE_SWING_PITCH := -8.0                # ตอนฟัน ใบอาวุธเกือบขนานพื้น
const POSE_THRUST := Vector2(0.0, -4.0)       # ตอนแทง ชี้ตรงไปข้างหน้า
var _death_screen: CanvasLayer
var _buffered_action: StringName = &""
var _buffer_left: int = 0

@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent
@onready var hitbox: Hitbox = $Hitbox
@onready var body: PlayerModel = $Model
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
	_create_mastery()
	_create_weapon_rig()
	equip(weapon)


# ---------------- WEAPON MASTERY ----------------
func _create_mastery() -> void:
	mastery = MasteryComponent.new()
	mastery.name = "Mastery"
	add_child(mastery)
	mastery.leveled_up.connect(_on_mastery_level_up)
	mastery.exp_gained.connect(func(_id: StringName, amount: int, reason: String) -> void:
		print("Mastery +%d (%s)" % [amount, reason]))
	hitbox.hit_landed.connect(_on_hit_landed_exp)


## ตีโดน → ได้ EXP ให้อาวุธที่ถืออยู่
func _on_hit_landed_exp(target: Hurtbox) -> void:
	var amount: float = mastery.exp_hit
	var reason: String = "hit"
	if target.damage_multiplier > 1.0:
		amount = mastery.exp_crit_hit
		reason = "crit"
	var is_training: bool = target.get_parent() is Dummy
	if target.health and target.health.is_dead and not is_training:
		amount += mastery.exp_kill
		reason += "+kill"
	if is_training:
		amount *= mastery.training_multiplier
	mastery.add_exp(weapon.id, amount, reason)


func _on_mastery_level_up(weapon_id: StringName, level: int) -> void:
	var data_name: String = String(weapon_id).capitalize()
	for w in weapon_slots:
		if w.id == weapon_id:
			data_name = w.display_name
	DamageNumber.spawn_text(get_tree().current_scene, global_position + Vector3(0, 0.4, 0), "%s Lv.%d!" % [data_name, level], Color(1.0, 0.8, 0.25))
	HitSpark.spawn(get_tree().current_scene, global_position + Vector3(0, 1.0, 0), Color(1.0, 0.85, 0.3), 30)
	if weapon_id == weapon.id:
		_apply_move_hitbox(_move if _move else weapon.get_move(0))


func _create_weapon_rig() -> void:
	_weapon_root = Node3D.new()
	_weapon_root.name = "WeaponRoot"
	body.add_child(_weapon_root)                  # อาวุธหมุนตามตัวโมเดล
	_swing_pivot = Node3D.new()
	_swing_pivot.name = "SwingPivot"
	_weapon_root.add_child(_swing_pivot)


## ถืออาวุธ — เปลี่ยนโมเดล และรีเซ็ตคอมโบ
func equip(data: WeaponData) -> void:
	weapon = data
	_combo_index = 0
	_frames_since_attack = 999
	if _hitbox_shape == null:
		_hitbox_shape = $Hitbox/CollisionShape3D as CollisionShape3D
		_hitbox_box = BoxShape3D.new()
		_hitbox_shape.shape = _hitbox_box
	_apply_move_hitbox(data.get_move(0))
	# เปลี่ยนโมเดลอาวุธ
	if _weapon_model:
		_weapon_model.queue_free()
		_weapon_model = null
	_weapon_root.position = data.hold_offset
	if data.model_scene:
		_weapon_model = data.model_scene.instantiate()
		_swing_pivot.add_child(_weapon_model)
		_weapon_model.position = data.grip_offset
	_set_pose(data.idle_pose.x, data.idle_pose.y)


## ปรับ Hitbox ตามท่า — ขนาด ระยะ ดาเมจ Hitstop
func _apply_move_hitbox(m: AttackMove) -> void:
	_hitbox_box.size = m.hitbox_size
	_hitbox_shape.position = Vector3(0, 0.75, -m.reach)
	if has_node("Hitbox/Visual"):
		var vis := $Hitbox/Visual as MeshInstance3D
		vis.position = _hitbox_shape.position
		vis.scale = m.hitbox_size / Vector3(1.1, 1.2, 1.0)
	var mult: float = mastery.damage_multiplier(weapon.id) if mastery else 1.0
	hitbox.damage = roundi(m.damage * mult)
	hitbox.hitstop_seconds = m.hitstop_seconds


## ท่าที่จะออกถ้ากดโจมตีตอนนี้ (ต่อคอมโบ หรือกลับไปท่าแรก)
func _next_move_index() -> int:
	if _frames_since_attack > weapon.combo_window_frames:
		return 0
	return _combo_index


## Stamina ที่ท่าถัดไปต้องใช้ — HUD ใช้แสดงสีแถบ
func next_attack_cost() -> float:
	return weapon.get_move(_next_move_index()).stamina_cost


## ชื่อท่าที่กำลังเล่น (สำหรับ HUD)
func current_move_name() -> String:
	return _move.move_name if (state == State.ATTACK and _move) else ""


func _set_pose(yaw_deg: float, pitch_deg: float) -> void:
	_swing_yaw_deg = yaw_deg
	_swing_pivot.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)


## ท่าถืออาวุธตามสถานะ — เรียกทุกเฟรม (Hitstop ทำให้อาวุธค้างกลางท่าเองโดยอัตโนมัติ)
func _update_weapon_pose() -> void:
	if _weapon_model == null:
		return
	_weapon_model.visible = state != State.DEAD
	var idle: Vector2 = weapon.idle_pose
	var grip: Vector3 = weapon.grip_offset
	_weapon_model.position = grip
	if state == State.PARRY:
		_set_pose(weapon.parry_pose.x, weapon.parry_pose.y)
		return
	if state != State.ATTACK or _move == null:
		_set_pose(idle.x, idle.y)
		return
	var s: int = _move.startup_frames
	var a: int = _move.active_frames
	var r: int = _move.recovery_frames
	var f: int = _state_frame
	if _move.kind == AttackMove.Kind.THRUST:
		# แทง: ดึงกลับ → พุ่งออกไปข้างหน้า → ดึงกลับมาท่าถือ
		var back: float = grip.z + _move.thrust_pullback
		var out: float = grip.z - _move.thrust_extend
		if f <= s:
			var t: float = ease(float(f) / s, 0.5)
			_set_pose(lerpf(idle.x, POSE_THRUST.x, t), lerpf(idle.y, POSE_THRUST.y, t))
			_weapon_model.position.z = lerpf(grip.z, back, t)
		elif f <= s + a:
			var t: float = ease(float(f - s) / a, 0.3)
			_set_pose(POSE_THRUST.x, POSE_THRUST.y)
			_weapon_model.position.z = lerpf(back, out, t)
		else:
			var t: float = ease(float(f - s - a) / r, 2.0)
			_set_pose(lerpf(POSE_THRUST.x, idle.x, t), lerpf(POSE_THRUST.y, idle.y, t))
			_weapon_model.position.z = lerpf(out, grip.z, t)
	else:
		# ฟัน/ปัด: ง้างไปด้านหนึ่ง → กวาดผ่านหน้าตัวไปอีกด้าน → กลับท่าถือ
		var p0: float = _move.sweep_pitch_from
		var p1: float = _move.sweep_pitch_to
		if f <= s:
			var t: float = ease(float(f) / s, 0.5)
			_set_pose(lerpf(idle.x, _move.sweep_from, t), lerpf(idle.y, p0, t))
		elif f <= s + a:
			var t: float = float(f - s) / a
			_set_pose(lerpf(_move.sweep_from, _move.sweep_to, t), lerpf(p0, p1, t))
		else:
			var t: float = ease(float(f - s - a) / r, 2.0)
			_set_pose(lerpf(_move.sweep_to, idle.x, t), lerpf(p1, idle.y, t))


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
	var perfect_end: int = iframe_start + perfect_dodge_frames + mastery.timing_bonus_frames(weapon.id) - 1
	if state == State.DODGE and _state_frame <= perfect_end:
		stamina.restore(perfect_dodge_refund)
		mastery.add_exp(weapon.id, mastery.exp_perfect_dodge, "perfect dodge")
		DamageNumber.spawn_text(get_tree().current_scene, global_position, "PERFECT!", Color(1.0, 0.85, 0.2))
		_slow_motion()
	else:
		DamageNumber.spawn_text(get_tree().current_scene, global_position, "DODGE!", Color(0.5, 0.9, 1.0))


## Parry สำเร็จ — ไม่เสียเลือด ได้ Stamina คืน และกลับมาขยับได้ทันทีเพื่อตีสวน
func _on_parried(_hitbox: Hitbox) -> void:
	hurtbox.parry_active = false
	stamina.restore(parry_stamina_refund)
	mastery.add_exp(weapon.id, mastery.exp_parry, "parry")
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
	_combo_queued = false
	_frames_since_attack = 999
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


# ---------------- ท่าทางโมเดล ----------------
func _update_model(delta: float) -> void:
	if state == State.DEAD:
		return
	# หันตัวตามทิศ — ตอนโจมตี/Parry หันเร็ว ตอนเดินหันนุ่ม ๆ
	var target_yaw: float = atan2(-facing.x, -facing.z)
	var turn_speed: float = 30.0 if state in [State.ATTACK, State.PARRY] else 14.0
	body.rotation.y = lerp_angle(body.rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))

	var speed: float = Vector2(velocity.x, velocity.z).length()
	var lean: float = 0.0
	var crouch: float = 0.0
	var twist: float = 0.0
	match state:
		State.NORMAL:
			lean = -0.1 * clampf(speed / walk_speed, 0.0, 1.0)
		State.ATTACK:
			speed = 0.0
			if _move and _move.kind == AttackMove.Kind.THRUST:
				lean = 0.1 if _state_frame <= _move.startup_frames else -0.25   # ง้างเอนหลัง → แทงพุ่งตัว
			else:
				twist = deg_to_rad(_swing_yaw_deg) * 0.45                     # บิดลำตัวตามดาบ
				lean = -0.08
		State.DODGE:
			speed = 0.0
			lean = -0.6
			crouch = 0.16
		State.PARRY:
			lean = 0.08
			crouch = 0.06
		State.HITSTUN:
			speed = 0.0
			lean = 0.35

	# มือจับอาวุธ: มือขวาที่ด้าม / มือซ้ายจับถัดขึ้นไป (เฉพาะท่าที่ใช้สองมือ เช่น หอกแทง)
	var right: Variant = null
	var left: Variant = null
	if _weapon_model and _weapon_model.visible:
		right = _weapon_model.global_position
		var two_hands: bool = weapon.two_handed
		if state == State.ATTACK and _move:
			two_hands = _move.two_handed
		if two_hands:
			left = _weapon_model.to_global(Vector3(0, 0, -weapon.off_hand_offset))
	body.update_pose(delta, speed, lean, crouch, twist, right, left)


# ---------------- กล้องสั่น ----------------
## สั่งให้กล้องสั่น — ค่าใหม่แรงกว่าค่าที่สั่นอยู่ถึงจะแทนที่
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	_update_model(delta)
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
	elif event is InputEventKey and event.pressed and not event.echo:
		# ปุ่ม 1–9 = สลับอาวุธ (เปลี่ยนได้เฉพาะตอนยืน/เดิน)
		var slot: int = event.keycode - KEY_1
		if slot >= 0 and slot < weapon_slots.size() and state == State.NORMAL:
			if weapon_slots[slot] != weapon:
				equip(weapon_slots[slot])
				DamageNumber.spawn_text(get_tree().current_scene, global_position, weapon.display_name, Color(0.8, 1.0, 0.8))



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
	if state != State.ATTACK:
		_frames_since_attack += 1


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
		var idx: int = _next_move_index()
		if stamina.try_spend(weapon.get_move(idx).stamina_cost):
			_start_attack(idx)
			return
		print("Stamina ไม่พอสำหรับโจมตี")

	_set_horizontal(move_dir * walk_speed)
	if move_dir.length() > 0.05:
		facing = move_dir.normalized()


# ---------------- ATTACK: Startup → Active → Recovery ----------------
func _start_attack(index: int) -> void:
	state = State.ATTACK
	_state_frame = 0
	_move_index = index % maxi(weapon.moves.size(), 1)
	_move = weapon.get_move(_move_index)
	_combo_queued = false
	_set_horizontal(Vector3.ZERO)
	if attack_toward_camera:
		facing = _camera_forward()  # หันไปทางที่กล้องมองก่อนโจมตี
	_apply_move_hitbox(_move)
	_update_facing_visual()


func _state_attack() -> void:
	_state_frame += 1
	_set_horizontal(Vector3.ZERO)

	var active_start: int = _move.startup_frames + 1
	var active_end: int = _move.startup_frames + _move.active_frames + 1
	var total: int = _move.total_frames()

	if _state_frame < active_start:
		body.modulate = TINT_STARTUP        # Startup: ตัวออกเหลือง
	elif _state_frame == active_start:
		body.modulate = TINT_NORMAL
		hitbox.activate()                   # Active: เปิด Hitbox
		_spawn_attack_effect()
	elif _state_frame == active_end:
		hitbox.deactivate()
		body.modulate = TINT_RECOVERY       # Recovery: ตัวออกเข้ม

	# ก้าวไปข้างหน้าระหว่างช่วง Active (เช่น หอกแทง)
	if _state_frame >= active_start and _state_frame < active_end and _move.step_forward > 0.0:
		_set_horizontal(facing * _move.step_forward)

	# กดโจมตีระหว่าง Recovery = ต่อคอมโบ
	if _state_frame >= active_end and _consume_buffer(&"attack"):
		_combo_queued = true

	if _state_frame >= total:
		body.modulate = TINT_NORMAL
		_combo_index = (_move_index + 1) % maxi(weapon.moves.size(), 1)
		_frames_since_attack = 0
		state = State.NORMAL
		if _combo_queued:
			_combo_queued = false
			if stamina.try_spend(weapon.get_move(_combo_index).stamina_cost):
				_start_attack(_combo_index)


## เอฟเฟกต์ตามชนิดท่า: แทง = รอยพุ่งตรง, ฟัน/ปัด = รอยโค้งตามทิศกวาด
func _spawn_attack_effect() -> void:
	var yaw: float = atan2(-facing.x, -facing.z)
	if _move.kind == AttackMove.Kind.THRUST:
		var length: float = _move.reach + _move.hitbox_size.z * 0.5
		SlashEffect.spawn_thrust(self, Vector3(0, 0.75, 0), yaw, length, weapon.slash_color)
	else:
		var sweep_sign: float = signf(_move.sweep_to - _move.sweep_from)
		var size: float = maxf(_move.reach / 0.85, 1.0)
		# ฟันเฉียง: เอียงรอยตามมุมเริ่ม-จบ (ด้านที่จบต่ำกว่า = ด้านนั้นลง)
		var tilt: float = (_move.sweep_pitch_to - _move.sweep_pitch_from) * 0.5 * -sweep_sign
		SlashEffect.spawn(self, Vector3(0, 0.8, 0), yaw - 0.25 * sweep_sign, weapon.slash_color, sweep_sign, size, tilt)


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
	if _state_frame <= parry_window + mastery.timing_bonus_frames(weapon.id):
		body.modulate = TINT_PARRY          # หน้าต่าง Parry: ตัวเรืองฟ้า
	else:
		hurtbox.parry_active = false
		body.modulate = TINT_RECOVERY       # พลาด: ค้างท่า โดนตีได้
	if _state_frame >= parry_window + mastery.timing_bonus_frames(weapon.id) + parry_recovery:
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
	# ล้มหงายหลัง
	var t := create_tween().set_parallel(true)
	t.tween_property(body, "modulate", TINT_DEAD, 0.4)
	t.tween_property(body, "rotation:x", 1.45, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
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
	body.rotation.x = 0.0
	state = State.NORMAL
	_state_frame = 0
	_buffered_action = &""
	get_tree().call_group("enemies", "reset_enemy")
