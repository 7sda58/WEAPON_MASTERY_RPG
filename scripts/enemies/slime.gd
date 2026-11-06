class_name Slime
extends CharacterBody3D
## ศัตรูพื้นฐาน — สไลม์
## เห็นผู้เล่น → เดินเข้าหา → ง้าง (Telegraph) → พุ่งชน → พักเหนื่อย (ช่องให้ผู้เล่นสวน)
## Task 3.12 / 3.16 (เวอร์ชันเล็กสำหรับ Prototype ตาม CR-009)
## โมเดล 3D (SlimeModel): หันหาเป้า, สีหน้า ปกติ / โกรธ (ง้าง-พุ่ง) / เจ็บ / มึน (CR-014)

enum State { IDLE, CHASE, TELEGRAPH, LUNGE, RECOVER, HITSTUN, STAGGERED, DEAD }


@export var display_name: String = "Slime"
## เลเวลศัตรู: HP +30% / ดาเมจ +20% / ตัวใหญ่ขึ้น 8% ต่อเลเวล — ฆ่าแล้วได้ Mastery EXP มากขึ้น
@export_range(1, 10) var level: int = 1

@export var detect_range: float = 8.0
@export var give_up_range: float = 14.0
## เข้าใกล้ระยะนี้แล้วเริ่มง้าง
@export var attack_range: float = 2.2
@export var move_speed: float = 2.2

@export_group("Attack (หน่วย: เฟรม)")
## ง้างนานแค่ไหนก่อนพุ่ง — ผู้เล่นต้องอ่านสัญญาณช่วงนี้
@export var telegraph_frames: int = 36
## กี่เฟรมสุดท้ายก่อนพุ่งที่ส่งสัญญาณ "หลบตอนนี้" (กระพริบขาว + ! แดง)
@export var dodge_cue_frames: int = 10
@export var lunge_frames: int = 12
@export var lunge_speed: float = 9.0
## พักหลังพุ่ง — ช่องให้ผู้เล่นตีสวน
@export var recover_frames: int = 50
@export var attack_damage: int = 12
## ชะงักเมื่อโดนตี (ระหว่างง้าง/พุ่งจะไม่ชะงัก)
@export var hitstun_frames: int = 12
@export var knockback_speed: float = 4.0
## เสียหลักนานแค่ไหนหลังโดน Parry — ช่วงนี้รับดาเมจ ×2
@export var stagger_frames: int = 75
@export var respawn_seconds: float = 3.0

var state: State = State.IDLE
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _frame: int = 0
var _lunge_dir: Vector3 = Vector3.FORWARD
var _spawn_pos: Vector3
var _flash_frames: int = 0
var _danger_mat: StandardMaterial3D
## ขนาดตัวตามเลเวล
var _size: float = 1.0
## ทิศที่สไลม์หัน
var _facing: Vector3 = Vector3.BACK

@onready var health: HealthComponent = $HealthComponent
@onready var body: SlimeModel = $Model
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var danger_zone: Node3D = $DangerZone
@onready var danger_mesh: MeshInstance3D = $DangerZone/Mesh
## แถบที่ค่อย ๆ ยาวออกไปจนสุดตอนพุ่ง = นาฬิกานับถอยหลังให้กดหลบ
@onready var danger_fill: Node3D = $DangerZone/FillPivot
## เครื่องหมาย "!" เหนือหัวตอนเริ่มง้าง
@onready var alert: Label3D = $Alert


func _ready() -> void:
	add_to_group("enemies")
	_spawn_pos = global_position
	# แยกวัสดุของแต่ละตัว ไม่ให้สไลม์หลายตัวกระพริบพร้อมกัน
	_danger_mat = danger_mesh.get_active_material(0).duplicate()
	danger_mesh.material_override = _danger_mat
	danger_zone.visible = false
	alert.visible = false
	# ปรับความแข็งแกร่งตามเลเวล
	health.max_health = roundi(health.max_health * (1.0 + 0.3 * (level - 1)))
	health.reset()
	attack_damage = roundi(attack_damage * (1.0 + 0.2 * (level - 1)))
	_size = 1.0 + 0.08 * (level - 1)
	_squash(Vector3.ONE)
	EnemyHealthBar.attach(self, health, display_name, level, 1.5 * _size)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hitbox.parried.connect(_on_parried)
	hitbox.hitstop_seconds = 0.09            # ถูกสไลม์ชน = หนักกว่าดาบเรา
	hitbox.hit_sound = &"hit_heavy"
	hitbox.spark_color = Color(1.0, 0.4, 0.3)


func _physics_process(delta: float) -> void:
	_frame += 1
	match state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase()
		State.TELEGRAPH:
			_state_telegraph()
		State.LUNGE:
			_state_lunge()
		State.RECOVER:
			_state_recover()
		State.HITSTUN:
			_state_hitstun()
		State.STAGGERED:
			_state_staggered()
		State.DEAD:
			_set_h(Vector3.ZERO)
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	if _flash_frames > 0:
		_flash_frames -= 1
		body.modulate = Color(3, 3, 3, 1)  # กระพริบสว่างเมื่อโดนตี


func _process(delta: float) -> void:
	var p := _player()
	match state:
		State.TELEGRAPH, State.LUNGE:
			body.set_expression(&"angry")
		State.HITSTUN, State.DEAD:
			body.set_expression(&"hurt")
		State.STAGGERED:
			body.set_expression(&"dizzy")
		_:
			body.set_expression(&"idle")
	# หันหาผู้เล่น ยกเว้นตอนง้าง/พุ่ง ที่หันตามทิศพุ่ง
	if state in [State.TELEGRAPH, State.LUNGE]:
		_facing = _lunge_dir
	elif p and state != State.DEAD:
		var to: Vector3 = _to_player(p)
		if to.length() > 0.1:
			_facing = to.normalized()
	body.face_toward(_facing, delta, 25.0 if state == State.TELEGRAPH else 8.0)


## ยุบ/ยืดตัว (คูณขนาดตามเลเวล)
func _squash(v: Vector3) -> void:
	body.scale = v * _size


func _set_state(s: State) -> void:
	state = s
	_frame = 0
	# เสียหลัก = รับดาเมจ ×2 (คริติคอล)
	hurtbox.damage_multiplier = 2.0 if s == State.STAGGERED else 1.0


func _set_h(v: Vector3) -> void:
	velocity.x = v.x
	velocity.z = v.z


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _to_player(p: Player) -> Vector3:
	var v: Vector3 = p.global_position - global_position
	v.y = 0.0
	return v


func _yaw_of(dir: Vector3) -> float:
	return atan2(-dir.x, -dir.z)


# ---------------- IDLE / CHASE ----------------
func _state_idle() -> void:
	_set_h(Vector3.ZERO)
	body.modulate = Color.WHITE
	_squash(Vector3.ONE)
	var p := _player()
	if p and p.state != Player.State.DEAD and _to_player(p).length() < detect_range:
		_set_state(State.CHASE)


func _state_chase() -> void:
	body.modulate = Color.WHITE
	var p := _player()
	if p == null or p.state == Player.State.DEAD or _to_player(p).length() > give_up_range:
		_set_state(State.IDLE)
		return
	var to: Vector3 = _to_player(p)
	if to.length() <= attack_range:
		_start_telegraph(to)
		return
	_set_h(to.normalized() * move_speed)
	# เด้งดึ๋ง ๆ ตอนเดิน
	var hop: float = absf(sin(_frame * 0.22))
	_squash(Vector3(1.0 - 0.08 * hop, 1.0 + 0.1 * hop, 1.0))


# ---------------- TELEGRAPH: ง้าง (สัญญาณเตือน) ----------------
func _start_telegraph(to_player: Vector3) -> void:
	_lunge_dir = to_player.normalized()  # ล็อกทิศพุ่งตั้งแต่ตอนเริ่มง้าง → ผู้เล่นหลบออกด้านข้างได้
	_set_state(State.TELEGRAPH)
	danger_zone.rotation.y = _yaw_of(_lunge_dir)
	hitbox.rotation.y = _yaw_of(_lunge_dir)
	danger_zone.visible = true
	danger_fill.scale = Vector3(1.0, 1.0, 0.01)
	Sfx.play_3d(get_tree().current_scene, &"warn_start", global_position, -3.0, 1.0, 0.0)
	# "!" เด้งขึ้นเหนือหัว
	alert.visible = true
	alert.modulate = Color(1.0, 0.9, 0.2)
	alert.scale = Vector3.ONE * 1.8
	create_tween().tween_property(alert, "scale", Vector3.ONE, 0.15)


func _state_telegraph() -> void:
	_set_h(Vector3.ZERO)
	var t: float = float(_frame) / telegraph_frames
	_squash(Vector3(1.0 + 0.3 * t, 1.0 - 0.3 * t, 1.0))   # ยุบตัวเตรียมพุ่ง
	body.modulate = Color.WHITE.lerp(Color(1.0, 0.35, 0.35), t)
	_danger_mat.albedo_color.a = 0.25 + 0.3 * t                # พื้นที่อันตรายเข้มขึ้นเรื่อย ๆ
	danger_fill.scale = Vector3(1.0, 1.0, maxf(t, 0.01))      # แถบยาวขึ้น — สุดแถบ = พุ่ง
	# ช่วงท้าย: ตัวกระพริบขาวจ้า + "!" เป็นสีแดง = "หลบตอนนี้!"
	if _frame == telegraph_frames - dodge_cue_frames + 1:
		# เสียง "ติ๊ง!" = หลบตอนนี้ — เสียงเดิมทุกครั้ง (ไม่สุ่ม pitch) ให้จำจังหวะได้
		Sfx.play_3d(get_tree().current_scene, &"warn_now", global_position, 2.0, 1.0, 0.0)
	if _frame > telegraph_frames - dodge_cue_frames:
		alert.modulate = Color(1.0, 0.25, 0.2)
		if _frame % 2 == 0:
			body.modulate = Color(3.0, 3.0, 3.0)
	if _frame >= telegraph_frames:
		danger_zone.visible = false
		alert.visible = false
		hitbox.damage = attack_damage
		hitbox.activate()
		Sfx.play_3d(get_tree().current_scene, &"slime_lunge", global_position, -2.0)
		_squash(Vector3(0.8, 1.25, 1.0))
		_set_state(State.LUNGE)


# ---------------- LUNGE: พุ่งชน ----------------
func _state_lunge() -> void:
	body.modulate = Color(1.0, 0.5, 0.5)
	_set_h(_lunge_dir * lunge_speed)
	if _frame >= lunge_frames:
		hitbox.deactivate()
		_set_state(State.RECOVER)


# ---------------- RECOVER: พักเหนื่อย = ช่องให้สวน ----------------
func _state_recover() -> void:
	_set_h(Vector3.ZERO)
	_squash(Vector3(1.1, 0.9, 1.0))
	body.modulate = Color(0.6, 0.6, 0.75)
	if _frame >= recover_frames:
		_set_state(State.CHASE)


# ---------------- HITSTUN: ชะงักเมื่อโดนตี ----------------
func _state_hitstun() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 0.5)
	velocity.z = move_toward(velocity.z, 0.0, 0.5)
	body.modulate = Color.WHITE
	if _frame >= hitstun_frames:
		_set_state(State.CHASE)


# ---------------- STAGGERED: โดน Parry → เสียหลัก ----------------
func _on_parried() -> void:
	danger_zone.visible = false
	alert.visible = false
	_set_state(State.STAGGERED)
	_set_h(-_lunge_dir * 5.0)  # กระเด็นถอยหลัง


func _state_staggered() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 0.4)
	velocity.z = move_toward(velocity.z, 0.0, 0.4)
	_squash(Vector3(1.15, 0.85, 1.0))
	# กระพริบเหลือง = "ตีเลย! ตอนนี้แรง ×2"
	body.modulate = Color(1.6, 1.4, 0.4) if (_frame / 6) % 2 == 0 else Color.WHITE
	if _frame >= stagger_frames:
		_set_state(State.CHASE)


# ---------------- โดนตี / ตาย / เกิดใหม่ ----------------
func _on_damaged(amount: int) -> void:
	if state == State.STAGGERED:
		DamageNumber.spawn_text(get_tree().current_scene, global_position, "%d!" % amount, Color(1.0, 0.8, 0.2))
	else:
		DamageNumber.spawn(get_tree().current_scene, global_position, amount)
	_flash_frames = 3
	# ระหว่างง้างหรือพุ่ง ไม่ชะงัก (Super Armor) — ต้องหลบก่อน แล้วค่อยตีตอนพัก
	if state in [State.IDLE, State.CHASE, State.RECOVER, State.HITSTUN]:
		var p := _player()
		if p:
			_set_h(-_to_player(p).normalized() * knockback_speed)
		_set_state(State.HITSTUN)


func _on_died() -> void:
	_set_state(State.DEAD)
	Sfx.play_3d(get_tree().current_scene, &"slime_die", global_position)
	hitbox.deactivate()
	danger_zone.visible = false
	alert.visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)
	var t := create_tween()
	t.tween_property(body, "modulate", Color(0.4, 0.4, 0.4, 0.0), 0.6)
	await get_tree().create_timer(respawn_seconds).timeout
	_respawn()


func _respawn() -> void:
	global_position = _spawn_pos
	velocity = Vector3.ZERO
	health.reset()
	$CollisionShape3D.set_deferred("disabled", false)
	hurtbox.set_deferred("monitorable", true)
	body.modulate = Color.WHITE
	_squash(Vector3.ONE)
	_set_state(State.IDLE)


## ผู้เล่นเกิดใหม่ → ศัตรูกลับจุดเดิม HP เต็ม
func reset_enemy() -> void:
	hitbox.deactivate()
	danger_zone.visible = false
	alert.visible = false
	_respawn()
