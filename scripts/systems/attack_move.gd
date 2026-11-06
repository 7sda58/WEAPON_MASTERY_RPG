class_name AttackMove
extends Resource
## ท่าโจมตีหนึ่งท่า — อาวุธหนึ่งชิ้นมีได้หลายท่าต่อกันเป็นคอมโบ
## Task 3.7 — Weapon Attack Patterns

enum Kind {
	SWEEP,   ## ฟัน/ปัด — กวาดเป็นวงโค้ง
	THRUST,  ## แทง — พุ่งตรงไปข้างหน้า
}

@export var move_name: String = "Slash"
@export var kind: Kind = Kind.SWEEP

@export_group("Frame Data (หน่วย: เฟรม)")
@export var startup_frames: int = 6
@export var active_frames: int = 4
@export var recovery_frames: int = 12

@export_group("Damage")
@export var damage: int = 10
@export var stamina_cost: float = 15.0
## เกมหยุดเมื่อตีโดน (วินาทีจริง)
@export var hitstop_seconds: float = 0.06

@export_group("Hitbox")
## ระยะจากตัวถึงกลางกล่องโจมตี (เมตร)
@export var reach: float = 0.85
## ขนาดกล่องโจมตี กว้าง × สูง × ลึก (เมตร)
@export var hitbox_size: Vector3 = Vector3(1.1, 1.2, 1.0)

@export_group("Sweep (ฟัน/ปัด)")
## มุมเริ่มและมุมจบ (องศา) — ค่าลบ = ทางขวาของตัว, ค่าบวก = ทางซ้าย
@export var sweep_from: float = -95.0
@export var sweep_to: float = 85.0
## มุมก้ม-เงยตอนเริ่มและจบ (องศา) — บวก = ยกสูง, ลบ = กดต่ำ
## เท่ากัน = กวาดแนวนอน, ต่างกัน = ฟันเฉียง
@export var sweep_pitch_from: float = -8.0
@export var sweep_pitch_to: float = -8.0

@export_group("Thrust (แทง)")
## ดึงอาวุธถอยหลังตอนง้าง (เมตร)
@export var thrust_pullback: float = 0.35
## ยื่นอาวุธออกไปตอนแทง (เมตร)
@export var thrust_extend: float = 0.8

@export_group("Grip")
## ใช้สองมือจับระหว่างท่านี้ (เช่น หอกแทง)
@export var two_handed: bool = false

@export_group("Movement")
## ก้าวไปข้างหน้าระหว่างช่วง Active (เมตรต่อวินาที, 0 = ยืนกับที่)
@export var step_forward: float = 0.0


func total_frames() -> int:
	return startup_frames + active_frames + recovery_frames
