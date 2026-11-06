class_name SpriteAnimator
extends RefCounted
## เลือกภาพจาก Sprite Sheet ตาม "ท่า" และ "มุมที่กล้องมองตัวละคร" (8 ทิศ)
## Task 2.6 — Animation System (ภาพชั่วคราว)
##
## รูปแบบ Sheet: คอลัมน์ = เฟรมของท่า, แถว = ท่า × 5 ทิศ
##   แถวในแต่ละท่า: 0 หน้า, 1 เฉียงหน้า-ขวา, 2 ข้าง-ขวา, 3 เฉียงหลัง-ขวา, 4 หลัง
##   ทิศซ้ายใช้ภาพทิศขวาแล้วกลับด้าน (flip_h) — วาดจริงแค่ 5 ทิศ
##
## ใช้งาน:
##   var anim := SpriteAnimator.new($Sprite3D, load("res://.../sheet.png"), 4, ANIMS)
##   anim.play(&"walk")           ← ทุกเฟรมใน _process
##   anim.update(delta, facing)

const DIRS: int = 5
## ช่อง 8 ทิศ (นับจาก "หันหนีกล้อง" ทวนเข็ม) → [แถวทิศ, กลับภาพ]
const SECTOR_TABLE := [[4, false], [3, true], [2, true], [1, true], [0, false], [1, false], [2, false], [3, false]]

var sprite: Sprite3D
## ชื่อท่า → {"row": ลำดับท่าใน Sheet, "frames": จำนวนเฟรม, "fps": ความเร็ว (0 = ค้างเฟรมเดียว)}
var anims: Dictionary
var _anim: StringName = &""
var _time: float = 0.0
var _fixed_frame: int = -1


func _init(target: Sprite3D, sheet: Texture2D, columns: int, anim_defs: Dictionary) -> void:
	sprite = target
	anims = anim_defs
	sprite.texture = sheet
	sprite.hframes = columns
	sprite.vframes = anim_defs.size() * DIRS


## เล่นท่า — fixed_frame >= 0 คือค้างไว้ที่เฟรมนั้น (เช่น ท่าโจมตีที่ผูกกับ Frame Data)
func play(anim_name: StringName, fixed_frame: int = -1) -> void:
	if anim_name != _anim:
		_anim = anim_name
		_time = 0.0
	_fixed_frame = fixed_frame


func update(delta: float, facing: Vector3) -> void:
	if not anims.has(_anim):
		return
	var a: Dictionary = anims[_anim]
	_time += delta
	var dir_row: int = 0
	var flip: bool = false
	var cam := sprite.get_viewport().get_camera_3d()
	if cam and facing.length() > 0.01:
		var cam_fwd: Vector3 = -cam.global_basis.z
		var cam_yaw: float = atan2(-cam_fwd.x, -cam_fwd.z)
		var face_yaw: float = atan2(-facing.x, -facing.z)
		var rel: float = wrapf(face_yaw - cam_yaw, -PI, PI)
		var sector: int = wrapi(roundi(rel / (PI / 4.0)), 0, 8)
		dir_row = SECTOR_TABLE[sector][0]
		flip = SECTOR_TABLE[sector][1]
	var frames: int = a["frames"]
	var fps: float = a["fps"]
	var idx: int = _fixed_frame if _fixed_frame >= 0 else (int(_time * fps) % frames)
	idx = clampi(idx, 0, frames - 1)
	sprite.flip_h = flip
	sprite.frame = (int(a["row"]) * DIRS + dir_row) * sprite.hframes + idx
