class_name TintableModel
extends Node3D
## โมเดล 3D ที่ "ย้อมสี" ได้ผ่านค่า modulate — ใช้แทน Sprite3D.modulate เดิม
## ทำงานโดยวางวัสดุโปร่งแสงทับทุกชิ้น (material_overlay):
##   ค่าเกิน 1 (เช่น Color(3,3,3))  → กระพริบสว่าง
##   alpha < 1                      → โปร่งแบบผี (ช่วงอมตะตอนหลบ)
##   alpha ≈ 0                      → ซ่อนทั้งตัว
##   สีเทา (เช่น 0.5,0.5,0.5)       → มืดลง
##   สีอื่น (เช่น เหลือง/แดง)        → ย้อมสีนั้น

var modulate: Color = Color.WHITE: set = set_modulate

var _overlay: StandardMaterial3D


func _ready() -> void:
	_overlay = StandardMaterial3D.new()
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.albedo_color = Color(1, 1, 1, 0)
	_apply_overlay(self)


func _apply_overlay(node: Node) -> void:
	for c in node.get_children():
		if c is GeometryInstance3D:
			(c as GeometryInstance3D).material_overlay = _overlay
		_apply_overlay(c)


func set_modulate(c: Color) -> void:
	modulate = c
	visible = c.a > 0.05
	if _overlay == null:
		return
	var hi: float = maxf(c.r, maxf(c.g, c.b))
	var lo: float = minf(c.r, minf(c.g, c.b))
	var o := Color(1, 1, 1, 0)
	if hi > 1.01:
		o = Color(c.r / hi, c.g / hi, c.b / hi, 0.7)         # กระพริบ
	elif c.a < 0.99:
		o = Color(0.6, 0.9, 1.0, 0.5)                          # โปร่งแบบผี
	elif hi > 0.97 and lo > 0.97:
		o = Color(1, 1, 1, 0)                                   # ปกติ
	elif hi - lo < 0.08:
		o = Color(0, 0, 0, (1.0 - (c.r + c.g + c.b) / 3.0) * 0.85)   # มืดลง
	else:
		o = Color(c.r, c.g, c.b, 0.4)                          # ย้อมสี
	_overlay.albedo_color = o
