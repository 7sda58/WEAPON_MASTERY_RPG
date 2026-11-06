class_name SlimeModel
extends TintableModel
## โมเดลสไลม์ Low-poly — เปลี่ยนสีหน้าตามสถานะ และหันหาเป้า
## การยุบ/ยืดตัวควบคุมจาก slime.gd ผ่าน scale ของโหนดนี้

@onready var face: Node3D = $Face
@onready var eye_l: Node3D = $Face/EyeL
@onready var eye_r: Node3D = $Face/EyeR
@onready var brow_l: Node3D = $Face/BrowL
@onready var brow_r: Node3D = $Face/BrowR
@onready var mouth: Node3D = $Face/Mouth
@onready var stars: Node3D = $Stars

var _expression: StringName = &""
var _time: float = 0.0


## สีหน้า: idle / angry / hurt / dizzy
func set_expression(e: StringName) -> void:
	if e == _expression:
		return
	_expression = e
	var angry: bool = e == &"angry"
	brow_l.visible = angry
	brow_r.visible = angry
	stars.visible = e == &"dizzy"
	var eye_scale := Vector3.ONE
	match e:
		&"hurt":
			eye_scale = Vector3(1.2, 0.25, 1.0)    # หลับตาปี๋
		&"angry":
			eye_scale = Vector3(1.1, 0.75, 1.0)    # ตาหรี่
		&"dizzy":
			eye_scale = Vector3(0.8, 0.8, 1.0)
	eye_l.scale = eye_scale
	eye_r.scale = eye_scale
	mouth.scale = Vector3(1.6, 1.0, 1.0) if angry else Vector3.ONE


## หันหน้าไปทางที่กำหนดอย่างนุ่มนวล
func face_toward(dir: Vector3, delta: float, speed: float = 10.0) -> void:
	if dir.length() < 0.01:
		return
	var yaw: float = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-speed * delta))


func _process(delta: float) -> void:
	_time += delta
	if stars.visible:
		stars.rotation.y += delta * 5.0
	# กะพริบตาทุก ~3 วินาที
	if _expression == &"idle" or _expression == &"":
		var blink: bool = fmod(_time, 3.2) < 0.12
		var sy: float = 0.15 if blink else 1.0
		eye_l.scale.y = sy
		eye_r.scale.y = sy
