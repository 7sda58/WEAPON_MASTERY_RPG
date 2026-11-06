class_name Sfx
extends RefCounted
## เล่นเสียงเอฟเฟกต์ — เรียกได้จากทุกที่ ไม่ต้องสร้าง node เอง
## ไฟล์เสียงอยู่ที่ assets/audio/sfx/<ชื่อ>.wav
##   Sfx.play_3d(get_tree().current_scene, &"hit", global_position)   ← เสียงมีทิศทาง (ดังเมื่อใกล้)
##   Sfx.play(get_tree().current_scene, &"level_up")                   ← เสียงทั่วไป (UI)

const DIR := "res://assets/audio/sfx/"

static var _cache: Dictionary = {}


static func _stream(sfx_name: StringName) -> AudioStream:
	if not _cache.has(sfx_name):
		var path: String = DIR + String(sfx_name) + ".wav"
		_cache[sfx_name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[sfx_name]


static func play_3d(world: Node, sfx_name: StringName, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0, pitch_jitter: float = 0.08) -> void:
	var s := _stream(sfx_name)
	if s == null or world == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	p.unit_size = 8.0
	p.max_distance = 45.0
	world.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


static func play(world: Node, sfx_name: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var s := _stream(sfx_name)
	if s == null or world == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch
	world.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
