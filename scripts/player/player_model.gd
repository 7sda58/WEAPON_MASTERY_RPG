class_name PlayerModel
extends TintableModel
## โมเดลผู้เล่นแบบ Low-poly — ขยับแขนขาด้วยโค้ด (ไม่ใช้ Animation)
## Task 2.6 — Animation System (ชั่วคราว)
## • เดิน: ขาและแขนแกว่งสลับ ตัวเด้งขึ้นลง
## • แขนที่ถืออาวุธ: ชี้ไปหาด้ามอาวุธทุกเฟรม (ท่าจับต่างกันตามอาวุธ)

## ความยาวแขน (ไหล่ → มือ)
const ARM_LENGTH: float = 0.44
const HIP_HEIGHT: float = 0.55

@onready var hips: Node3D = $Hips
@onready var torso: Node3D = $Hips/Torso
@onready var head: Node3D = $Hips/Torso/Head
@onready var leg_l: Node3D = $Hips/LegL
@onready var leg_r: Node3D = $Hips/LegR
@onready var shoulder_l: Node3D = $Hips/Torso/ShoulderL
@onready var shoulder_r: Node3D = $Hips/Torso/ShoulderR
@onready var arm_l: Node3D = $Hips/Torso/ShoulderL/ArmL
@onready var arm_r: Node3D = $Hips/Torso/ShoulderR/ArmR

var _walk_phase: float = 0.0
var _walk_amount: float = 0.0
var _time: float = 0.0


## เรียกทุกเฟรมจาก player.gd
## speed = ความเร็วแนวราบ, lean = เอนตัว (ลบ = ไปข้างหน้า), crouch = ย่อตัว (เมตร), twist = บิดลำตัว (เรเดียน)
## right_target / left_target = ตำแหน่งโลกที่มือต้องจับ (null = แขนแกว่งอิสระ)
func update_pose(delta: float, speed: float, lean: float, crouch: float, twist: float, right_target: Variant, left_target: Variant) -> void:
	_time += delta
	var want: float = clampf(speed / 4.0, 0.0, 1.0)
	_walk_amount = lerpf(_walk_amount, want, 1.0 - exp(-12.0 * delta))
	if speed > 0.2:
		_walk_phase += delta * (5.0 + speed * 1.6)
	var swing: float = sin(_walk_phase) * 0.75 * _walk_amount
	leg_l.rotation.x = swing
	leg_r.rotation.x = -swing
	# เด้งตอนเดิน + หายใจตอนยืน
	var bob: float = absf(cos(_walk_phase)) * 0.05 * _walk_amount
	hips.position.y = HIP_HEIGHT - crouch + bob
	torso.rotation = Vector3(lean, twist, 0.0)
	torso.scale.y = 1.0 + sin(_time * 2.2) * 0.012 * (1.0 - _walk_amount)
	head.rotation = Vector3(-lean * 0.45, -twist * 0.4, 0.0)
	# งอเข่าเวลาย่อ
	if crouch > 0.01:
		leg_l.rotation.x += 0.5
		leg_r.rotation.x -= 0.3
	_aim_arm(shoulder_r, arm_r, right_target, -swing)
	_aim_arm(shoulder_l, arm_l, left_target, swing)


func _aim_arm(shoulder: Node3D, arm: Node3D, target: Variant, swing: float) -> void:
	if target == null:
		# แขนห้อยและแกว่งตามจังหวะเดิน
		shoulder.rotation = Vector3(-PI / 2.0 + swing, 0.0, 0.0)
		arm.scale = Vector3.ONE
		return
	var d: Vector3 = (target as Vector3) - shoulder.global_position
	var dist: float = d.length()
	if dist < 0.05:
		return
	var dir: Vector3 = d / dist
	var up: Vector3 = Vector3.UP if absf(dir.y) < 0.98 else Vector3.FORWARD
	var s: Vector3 = shoulder.global_basis.get_scale()
	shoulder.global_basis = Basis.looking_at(dir, up).scaled(s)
	# ยืด/หดแขนเล็กน้อยให้มือถึงด้ามพอดี
	arm.scale = Vector3(1.0, 1.0, clampf(dist / ARM_LENGTH, 0.55, 1.35))
