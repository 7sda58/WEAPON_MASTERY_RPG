class_name WorldDecor
extends Node3D
## ตกแต่งแผนที่อัตโนมัติ: ต้นไม้ หิน พุ่มไม้ หญ้า ดอกไม้ และพื้นดินลายธรรมชาติ
## สร้างใหม่ทุกครั้งที่เริ่มเกม จากค่า Seed เดียวกัน = ได้แผนที่เดิมทุกครั้ง
## ปรับจำนวนได้ใน Inspector ของ node นี้ (ฉาก test_arena)

@export var seed_value: int = 1234
## รัศมีพื้นที่ตกแต่ง (เมตร)
@export var area_radius: float = 36.0
## พื้นที่โล่งรอบจุดเกิด (ไม่มีต้นไม้/หิน)
@export var clear_radius: float = 7.0

@export_group("Counts")
@export var pine_trees: int = 55
@export var round_trees: int = 25
@export var bushes: int = 45
@export var rocks: int = 35
@export var pebbles: int = 120
@export var grass_tufts: int = 9000
@export var flowers: int = 700
@export var dirt_patches: int = 10

@export_group("Ambience")
## เสียงลมพื้นหลัง (วนซ้ำ)
@export var wind_volume_db: float = -14.0

@export_group("Ground")
## MeshInstance3D ของพื้น — ใส่ลายพื้นให้อัตโนมัติ
@export var ground_mesh: MeshInstance3D

var _rng := RandomNumberGenerator.new()
var _occupied: Array[Vector3] = []   # จุดที่วางของแล้ว (x, z, รัศมี)
var _mats: Dictionary = {}


func _ready() -> void:
	_rng.seed = seed_value
	_build_materials()
	if ground_mesh:
		_paint_ground()
	_spawn_dirt_patches()
	for i in pine_trees:
		_try_place(1.2, _make_pine)
	for i in round_trees:
		_try_place(1.6, _make_round_tree)
	for i in rocks:
		_try_place(1.0, _make_rock)
	for i in bushes:
		_try_place(0.8, _make_bush, 3.0)
	_spawn_pebbles()
	_spawn_grass()
	_spawn_flowers()
	_start_wind()


func _start_wind() -> void:
	var path := "res://assets/audio/sfx/wind_loop.wav"
	if not ResourceLoader.exists(path):
		return
	var s := load(path) as AudioStreamWAV
	if s:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	var p := AudioStreamPlayer.new()
	p.name = "WindAmbience"
	p.stream = s
	p.volume_db = wind_volume_db
	add_child(p)
	p.play()


# ---------------- วัสดุ ----------------
func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _build_materials() -> void:
	_mats["trunk"] = [_mat(Color(0.55, 0.33, 0.18)), _mat(Color(0.45, 0.27, 0.15))]
	_mats["pine"] = [_mat(Color(0.18, 0.55, 0.38)), _mat(Color(0.22, 0.65, 0.45)), _mat(Color(0.14, 0.45, 0.32))]
	_mats["leaf"] = [_mat(Color(0.35, 0.68, 0.28)), _mat(Color(0.45, 0.75, 0.3)), _mat(Color(0.55, 0.72, 0.25))]
	_mats["bush"] = [_mat(Color(0.28, 0.58, 0.25)), _mat(Color(0.34, 0.64, 0.3))]
	_mats["rock"] = [_mat(Color(0.58, 0.58, 0.6)), _mat(Color(0.5, 0.5, 0.53)), _mat(Color(0.64, 0.62, 0.58))]
	_mats["moss"] = [_mat(Color(0.38, 0.55, 0.3))]
	_mats["dirt"] = [_mat(Color(0.52, 0.42, 0.3), 1.0)]
	_mats["fruit"] = [_mat(Color(0.9, 0.3, 0.25), 0.5)]


func _pick(key: String) -> StandardMaterial3D:
	var arr: Array = _mats[key]
	return arr[_rng.randi() % arr.size()]


# ---------------- การวางของ ----------------
## หาจุดว่างแล้วเรียก maker(ตำแหน่ง) — ลองสุ่มหลายครั้งถ้าทับกัน
func _try_place(radius: float, maker: Callable, min_from_center: float = -1.0) -> void:
	var min_r: float = clear_radius if min_from_center < 0.0 else min_from_center
	for attempt in 12:
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf_range(pow(min_r / area_radius, 2.0), 1.0)) * area_radius
		var pos := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var ok := true
		for o in _occupied:
			if Vector2(pos.x - o.x, pos.z - o.z).length() < radius + o.y:
				ok = false
				break
		if ok:
			_occupied.append(Vector3(pos.x, radius, pos.z))
			maker.call(pos)
			return


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _body(pos: Vector3, yaw: float = 0.0) -> StaticBody3D:
	var b := StaticBody3D.new()
	add_child(b)
	b.position = pos
	b.rotation.y = yaw
	return b


func _collider(b: StaticBody3D, shape: Shape3D, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = pos
	b.add_child(cs)


func _cyl(top: float, bottom: float, h: float, seg: int = 6) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


func _sphere(r: float, seg: int = 7, rings: int = 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = rings
	return m


# ---------------- ต้นสน: ลำต้น + กรวยซ้อน 3 ชั้น ----------------
func _make_pine(pos: Vector3) -> void:
	var s: float = _rng.randf_range(0.8, 1.5)
	var b := _body(pos, _rng.randf() * TAU)
	b.scale = Vector3.ONE * s
	b.rotation.x = _rng.randf_range(-0.04, 0.04)
	b.rotation.z = _rng.randf_range(-0.04, 0.04)
	_collider(b, _cyl_shape(0.25, 2.0), Vector3(0, 1.0, 0))
	_mesh(b, _cyl(0.13, 0.2, 1.2), _pick("trunk"), Vector3(0, 0.6, 0))
	var mat := _pick("pine")
	var layers := [[1.05, 1.5, 1.6], [0.82, 1.3, 2.3], [0.58, 1.1, 2.95]]
	for l in layers:
		_mesh(b, _cyl(0.0, l[0], l[1], 7), mat, Vector3(0, l[2], 0), Vector3(0, _rng.randf() * TAU, 0))


# ---------------- ต้นไม้พุ่มกลม: ลำต้น + ก้อนใบหลายก้อน ----------------
func _make_round_tree(pos: Vector3) -> void:
	var s: float = _rng.randf_range(0.9, 1.4)
	var b := _body(pos, _rng.randf() * TAU)
	b.scale = Vector3.ONE * s
	_collider(b, _cyl_shape(0.28, 2.0), Vector3(0, 1.0, 0))
	_mesh(b, _cyl(0.14, 0.24, 1.8), _pick("trunk"), Vector3(0, 0.9, 0))
	_mesh(b, _cyl(0.05, 0.09, 0.7), _pick("trunk"), Vector3(0.25, 1.6, 0), Vector3(0, 0, -0.7))
	var mat := _pick("leaf")
	_mesh(b, _sphere(1.0), mat, Vector3(0, 2.4, 0))
	for i in _rng.randi_range(2, 4):
		var a: float = _rng.randf() * TAU
		_mesh(b, _sphere(_rng.randf_range(0.55, 0.8)), mat, Vector3(cos(a) * 0.75, _rng.randf_range(1.9, 2.7), sin(a) * 0.75))
	if _rng.randf() < 0.4:   # ผลไม้สีแดง
		for i in 4:
			var a: float = _rng.randf() * TAU
			_mesh(b, _sphere(0.08, 6, 3), _mats["fruit"][0], Vector3(cos(a) * 0.95, _rng.randf_range(2.0, 2.6), sin(a) * 0.95), Vector3.ZERO, Vector3.ONE, false)


# ---------------- พุ่มไม้ ----------------
func _make_bush(pos: Vector3) -> void:
	var b := Node3D.new()
	add_child(b)
	b.position = pos
	var mat := _pick("bush")
	var s: float = _rng.randf_range(0.6, 1.1)
	for i in _rng.randi_range(2, 4):
		var off := Vector3(_rng.randf_range(-0.4, 0.4), 0, _rng.randf_range(-0.4, 0.4)) * s
		var r: float = _rng.randf_range(0.35, 0.55) * s
		_mesh(b, _sphere(r, 6, 3), mat, off + Vector3(0, r * 0.7, 0))


# ---------------- หิน: ก้อนใหญ่ + ก้อนเล็กเกาะ + มอส ----------------
func _make_rock(pos: Vector3) -> void:
	var s: float = _rng.randf_range(0.6, 1.8)
	var b := _body(pos, _rng.randf() * TAU)
	var mat := _pick("rock")
	var main := BoxMesh.new()
	main.size = Vector3(1.0, 0.75, 0.9) * s
	_mesh(b, main, mat, Vector3(0, 0.3 * s, 0), Vector3(_rng.randf_range(-0.25, 0.25), 0, _rng.randf_range(-0.25, 0.25)))
	var top := PrismMesh.new()
	top.size = Vector3(0.8, 0.45, 0.75) * s
	_mesh(b, top, mat, Vector3(0.05 * s, 0.8 * s, 0), Vector3(0, _rng.randf() * TAU, _rng.randf_range(-0.2, 0.2)))
	for i in _rng.randi_range(1, 3):
		var small := BoxMesh.new()
		small.size = Vector3.ONE * _rng.randf_range(0.25, 0.45) * s
		var a: float = _rng.randf() * TAU
		_mesh(b, small, _pick("rock"), Vector3(cos(a) * 0.6 * s, 0.1 * s, sin(a) * 0.55 * s), Vector3(_rng.randf() * 0.6, _rng.randf() * TAU, _rng.randf() * 0.6))
	if _rng.randf() < 0.5:   # มอสบนหัวหิน
		var moss := BoxMesh.new()
		moss.size = Vector3(0.7, 0.06, 0.6) * s
		_mesh(b, moss, _mats["moss"][0], Vector3(0, 0.69 * s, 0), Vector3(0, _rng.randf(), 0), Vector3.ONE, false)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 1.1, 0.9) * s
	_collider(b, shape, Vector3(0, 0.5 * s, 0))


func _spawn_pebbles() -> void:
	for i in pebbles:
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf()) * area_radius
		var m := BoxMesh.new()
		m.size = Vector3(_rng.randf_range(0.08, 0.2), _rng.randf_range(0.05, 0.1), _rng.randf_range(0.08, 0.18))
		_mesh(self, m, _pick("rock"), Vector3(cos(a) * r, 0.03, sin(a) * r), Vector3(0, _rng.randf() * TAU, 0), Vector3.ONE, false)


func _spawn_dirt_patches() -> void:
	for i in dirt_patches:
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(4.0, area_radius)
		var m := _cyl(_rng.randf_range(1.2, 2.6), _rng.randf_range(1.2, 2.6), 0.02, 9)
		_mesh(self, m, _mats["dirt"][0], Vector3(cos(a) * r, 0.005, sin(a) * r), Vector3(0, _rng.randf() * TAU, 0), Vector3(1, 1, _rng.randf_range(0.6, 1.0)), false)


func _cyl_shape(radius: float, height: float) -> CylinderShape3D:
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = height
	return c


# ---------------- หญ้าและดอกไม้ (MultiMesh = วาดทีเดียวหลายพันกอ) ----------------
## กอหญ้า: ใบสามเหลี่ยม 4 ใบไขว้กัน สีโคนเข้ม ปลายอ่อน
func _grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_col := Color(0.2, 0.42, 0.16, 0.0)
	var tip_col := Color(0.55, 0.85, 0.35, 1.0)
	for i in 4:
		var a: float = i * PI / 4.0 + 0.3
		var dir := Vector3(cos(a), 0, sin(a))
		var lean := Vector3(-sin(a), 0, cos(a)) * 0.06 * (1 if i % 2 == 0 else -1)
		var w: float = 0.05
		var h: float = 0.32 + 0.08 * (i % 2)
		st.set_color(base_col); st.add_vertex(-dir * w)
		st.set_color(base_col); st.add_vertex(dir * w)
		st.set_color(tip_col); st.add_vertex(Vector3(0, h, 0) + lean)
	return st.commit()


func _flower_mesh(petal: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := Color(0.25, 0.5, 0.2, 0.0)
	# ก้าน
	for q in [[Vector3(-0.01, 0, 0), Vector3(0.01, 0, 0), Vector3(0, 0.22, 0)]]:
		for v in q:
			st.set_color(stem); st.add_vertex(v)
	# กลีบ 2 แผ่นไขว้
	for i in 2:
		var a: float = i * PI / 2.0
		var d := Vector3(cos(a), 0, sin(a)) * 0.06
		var c := Vector3(0, 0.24, 0)
		var up := Vector3(0, 0.06, 0)
		for v in [c - d - up, c + d - up, c + d + up, c - d - up, c + d + up, c - d + up]:
			st.set_color(Color(petal.r, petal.g, petal.b, 0.0)); st.add_vertex(v)
	return st.commit()


func _multimesh(mesh: Mesh, count: int, min_s: float, max_s: float, avoid_center: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	for i in count:
		var a: float = _rng.randf() * TAU
		var r: float = sqrt(_rng.randf_range(pow(avoid_center / area_radius, 2.0), 1.0)) * (area_radius + 4.0)
		var s: float = _rng.randf_range(min_s, max_s)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.8, 1.3), s))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(cos(a) * r, 0.0, sin(a) * r)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


func _grass_material() -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/shaders/grass.gdshader")
	return sm


func _spawn_grass() -> void:
	var mmi := _multimesh(_grass_mesh(), grass_tufts, 0.7, 1.4, 0.0)
	mmi.material_override = _grass_material()


func _spawn_flowers() -> void:
	var colors := [Color(0.95, 0.35, 0.3), Color(1.0, 0.65, 0.2), Color(0.98, 0.95, 0.9), Color(0.85, 0.5, 0.95)]
	var per: int = flowers / colors.size()
	for c in colors:
		var mmi := _multimesh(_flower_mesh(c), per, 0.8, 1.3, 2.0)
		mmi.material_override = _grass_material()


# ---------------- พื้นดิน: ลายหญ้าเข้ม/อ่อน จาก Noise ----------------
func _paint_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var grad := Gradient.new()
	grad.set_color(0, Color(0.33, 0.55, 0.22))
	grad.set_color(1, Color(0.5, 0.7, 0.3))
	grad.add_point(0.5, Color(0.42, 0.63, 0.27))
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.noise = noise
	tex.color_ramp = grad
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 1.0
	m.uv1_scale = Vector3(4, 4, 1)
	ground_mesh.material_override = m
