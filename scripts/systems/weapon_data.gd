class_name WeaponData
extends Resource
## ข้อมูลอาวุธหนึ่งชนิด — เก็บเป็นไฟล์ .tres ใน data/weapons/
## Task 3.1 Weapon Base System / Task 3.2 Weapon Data
## เพิ่มอาวุธใหม่ = สร้างไฟล์ .tres ใหม่ ไม่ต้องแก้โค้ดผู้เล่น

@export var id: StringName = &"sword"
@export var display_name: String = "Sword"

@export_group("Attack (หน่วย: เฟรม)")
## ช่วงง้าง — ยังไม่โดน
@export var startup_frames: int = 6
## ช่วงที่ Hitbox เปิด — โดนได้
@export var active_frames: int = 4
## ช่วงฟื้นตัว — ขยับไม่ได้ เปิดช่องให้ถูกสวน
@export var recovery_frames: int = 12
@export var damage: int = 10
@export var stamina_cost: float = 15.0

@export_group("Hitbox")
## ระยะจากตัวถึงกลางกล่องโจมตี (เมตร)
@export var reach: float = 0.85
## ขนาดกล่องโจมตี กว้าง × สูง × ลึก (เมตร)
@export var hitbox_size: Vector3 = Vector3(1.1, 1.2, 1.0)

@export_group("Model")
## โมเดลอาวุธที่ถือ (ด้ามที่จุด 0,0,0 ใบชี้ไปทาง -Z)
@export var model_scene: PackedScene
## มุมกวาด (องศา): ง้างไปทางขวา → ฟันไปทางซ้าย
@export var windup_angle: float = -95.0
@export var swing_end_angle: float = 85.0

@export_group("Feedback")
## เกมหยุดเมื่อตีโดน (วินาทีจริง) — อาวุธหนักควรนานกว่า
@export var hitstop_seconds: float = 0.06
@export var slash_color: Color = Color(1.0, 0.97, 0.8)


## รวมเฟรมทั้งท่า
func total_frames() -> int:
	return startup_frames + active_frames + recovery_frames
