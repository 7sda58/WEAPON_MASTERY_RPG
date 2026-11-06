class_name EnemyHealthBar
extends Node3D
## แถบเลือด + ชื่อ + เลเวล ลอยเหนือหัวศัตรู
## แสดงเมื่อผู้เล่นอยู่ใกล้ หรือเพิ่งโดนตี — ซ่อนเมื่อตาย
## เรียกใช้: EnemyHealthBar.attach(self, health, "Slime", 2, 1.3)

const SHADER := preload("res://assets/shaders/health_bar.gdshader")

## ระยะที่เริ่มแสดง (เมตร)
var show_distance: float = 14.0
var _health: HealthComponent
var _mat: ShaderMaterial
var _label: Label3D
var _ghost: float = 1.0
var _fill: float = 1.0
var _recent_hit: float = 0.0


static func attach(owner_node: Node3D, health: HealthComponent, title: String, level: int, height: float, width: float = 1.0) -> EnemyHealthBar:
	var bar := EnemyHealthBar.new()
	bar._health = health
	owner_node.add_child(bar)
	bar.position = Vector3(0, height, 0)
	bar._build(title, level, width)
	return bar


func _build(title: String, level: int, width: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, 0.11)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("bar_size", Vector2(width, 0.11))
	_mat.render_priority = 5
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

	_label = Label3D.new()
	_label.text = ("Lv.%d  %s" % [level, title]) if level > 0 else title
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = false
	_label.pixel_size = 0.004
	_label.font_size = 40
	_label.outline_size = 12
	_label.render_priority = 6
	_label.outline_render_priority = 5
	_label.modulate = _level_color(level)
	_label.position = Vector3(0, 0.17, 0)
	add_child(_label)

	_health.health_changed.connect(_on_health_changed)
	_on_health_changed(_health.current_health, _health.max_health)


## สีชื่อตามเลเวล: 1 ขาว, 2 เหลือง, 3 ส้ม, 4+ แดง
func _level_color(level: int) -> Color:
	match level:
		0, 1:
			return Color(0.95, 0.95, 0.95)
		2:
			return Color(1.0, 0.9, 0.35)
		3:
			return Color(1.0, 0.6, 0.2)
	return Color(1.0, 0.3, 0.25)


func _on_health_changed(current: int, maximum: int) -> void:
	var new_fill: float = float(current) / maxf(maximum, 1)
	if new_fill < _fill:
		_recent_hit = 4.0
	_fill = new_fill
	if _fill >= _ghost:
		_ghost = _fill   # ฟื้นเลือด → แถบจางตามทันที
	_mat.set_shader_parameter("fill", _fill)


func _process(delta: float) -> void:
	# แถบสีอ่อนค่อย ๆ ลดตามแถบจริง (หลังโดนตีครู่หนึ่ง)
	if _ghost > _fill:
		_ghost = move_toward(_ghost, _fill, delta * 0.6)
		_mat.set_shader_parameter("ghost", _ghost)
	_recent_hit = maxf(_recent_hit - delta, 0.0)
	var should_show: bool = not _health.is_dead
	if should_show:
		var p := get_tree().get_first_node_in_group("player") as Node3D
		var near: bool = p != null and p.global_position.distance_to(global_position) < show_distance
		should_show = near or _recent_hit > 0.0
	visible = should_show
