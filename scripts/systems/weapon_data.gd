class_name WeaponData
extends Resource
## ข้อมูลอาวุธหนึ่งชนิด — เก็บเป็นไฟล์ .tres ใน data/weapons/
## Task 3.1 Weapon Base System / Task 3.2 Weapon Data / Task 3.7 Attack Patterns
## เพิ่มอาวุธใหม่ = สร้างไฟล์ .tres ใหม่ ไม่ต้องแก้โค้ดผู้เล่น

@export var id: StringName = &"sword"
@export var display_name: String = "Sword"

@export_group("Combo")
## ท่าโจมตีเรียงตามคอมโบ (AttackMove) — กดโจมตีต่อเนื่องจะออกท่าถัดไป
@export var moves: Array[Resource] = []
## หลังจบท่า ถ้ากดโจมตีภายในกี่เฟรมจะต่อคอมโบ (เกินนี้กลับไปท่าแรก)
@export var combo_window_frames: int = 18

@export_group("Model")
## โมเดลอาวุธที่ถือ (จุดจับอยู่ที่ 0,0,0 ปลายชี้ไปทาง -Z)
@export var model_scene: PackedScene
## ตำแหน่งมือจับเทียบกับกลางอก (เมตร)
@export var grip_offset: Vector3 = Vector3(0, 0, -0.22)
## ท่าถือปกติ (องศา): x = หันซ้าย-ขวา, y = ก้ม-เงย
@export var idle_pose: Vector2 = Vector2(-55.0, -55.0)
## ท่าตั้งรับตอน Parry
@export var parry_pose: Vector2 = Vector2(-15.0, 35.0)

@export_group("Feedback")
@export var slash_color: Color = Color(1.0, 0.97, 0.8)


func get_move(index: int) -> AttackMove:
	if moves.is_empty():
		return AttackMove.new()
	return moves[index % moves.size()] as AttackMove
