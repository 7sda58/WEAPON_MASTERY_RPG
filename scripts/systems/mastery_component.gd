class_name MasteryComponent
extends Node
## Weapon Mastery — อาวุธแต่ละชนิดเก็บ EXP และเลเวลแยกกัน
## Task 3.8 Mastery EXP / Task 3.9 Mastery Levels
## หลักการ: เล่นแม่น (Perfect Dodge / Parry / ตีตอนศัตรูเสียหลัก) ได้ EXP มากกว่าตีธรรมดา
##          ตีหุ่นฝึกได้ครึ่งเดียว — กันการฟาร์ม

signal exp_gained(weapon_id: StringName, amount: int, reason: String)
signal leveled_up(weapon_id: StringName, new_level: int)

## EXP สะสมที่ต้องมีเพื่อถึงเลเวล 2, 3, 4, 5 (เลเวลสูงสุด 5)
const LEVEL_EXP: Array[int] = [0, 40, 110, 220, 380]

@export_group("EXP ต่อการกระทำ")
@export var exp_hit: int = 2
## ตีโดนตอนศัตรูเสียหลัก (คริติคอล)
@export var exp_crit_hit: int = 5
@export var exp_kill: int = 8
## Perfect Dodge / Parry = ×3 ของการตีธรรมดา
@export var exp_perfect_dodge: int = 6
@export var exp_parry: int = 6
## ตัวคูณเมื่อตีหุ่นฝึก
@export var training_multiplier: float = 0.5

@export_group("โบนัสต่อเลเวล")
## ดาเมจเพิ่มต่อเลเวล (0.05 = +5%)
@export var damage_bonus_per_level: float = 0.05

var _exp: Dictionary = {}          # weapon_id → EXP สะสม
var _fraction: Dictionary = {}     # เศษ EXP จากตัวคูณ (เช่น 0.5)


func get_exp(weapon_id: StringName) -> int:
	return _exp.get(weapon_id, 0)


func get_level(weapon_id: StringName) -> int:
	var e: int = get_exp(weapon_id)
	var lv: int = 1
	for i in range(1, LEVEL_EXP.size()):
		if e >= LEVEL_EXP[i]:
			lv = i + 1
	return lv


func max_level() -> int:
	return LEVEL_EXP.size()


## ความคืบหน้าในเลเวลปัจจุบัน: x = EXP ที่มีในเลเวลนี้, y = EXP ที่ต้องใช้ทั้งเลเวล (y = 0 คือเลเวลสูงสุดแล้ว)
func get_progress(weapon_id: StringName) -> Vector2i:
	var lv: int = get_level(weapon_id)
	if lv >= max_level():
		return Vector2i(0, 0)
	var start: int = LEVEL_EXP[lv - 1]
	return Vector2i(get_exp(weapon_id) - start, LEVEL_EXP[lv] - start)


func add_exp(weapon_id: StringName, amount: float, reason: String = "") -> void:
	if amount <= 0.0:
		return
	var total: float = amount + _fraction.get(weapon_id, 0.0)
	var whole: int = floori(total)
	_fraction[weapon_id] = total - whole
	if whole <= 0:
		return
	var before: int = get_level(weapon_id)
	_exp[weapon_id] = get_exp(weapon_id) + whole
	exp_gained.emit(weapon_id, whole, reason)
	var after: int = get_level(weapon_id)
	if after > before:
		leveled_up.emit(weapon_id, after)


## ตัวคูณดาเมจของอาวุธนี้ตามเลเวล
func damage_multiplier(weapon_id: StringName) -> float:
	return 1.0 + damage_bonus_per_level * (get_level(weapon_id) - 1)


## หน้าต่าง Perfect Dodge / Parry กว้างขึ้น 1 เฟรมทุก 2 เลเวล (Lv3 +1, Lv5 +2)
func timing_bonus_frames(weapon_id: StringName) -> int:
	return (get_level(weapon_id) - 1) / 2
