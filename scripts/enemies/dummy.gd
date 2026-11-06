class_name Dummy
extends StaticBody3D
## หุ่นฝึก — เป้าทดสอบการโจมตี ไม่ขยับ ไม่ตีกลับ
## ถูกตีจนหมด HP แล้วจะฟื้นเองหลัง 1 วินาที

@export var respawn_time: float = 1.0

@onready var health: HealthComponent = $HealthComponent
@onready var body: Sprite3D = $Sprite3D


func _ready() -> void:
	EnemyHealthBar.attach(self, health, "Training Dummy", 0, 1.8)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _on_damaged(amount: int) -> void:
	print("Dummy โดน %d  เหลือ %d" % [amount, health.current_health])
	DamageNumber.spawn(get_tree().current_scene, global_position, amount)
	# กระพริบสว่างสั้น ๆ ให้รู้ว่าโดน
	body.modulate = Color(3, 3, 3, 1)
	await get_tree().create_timer(0.08).timeout
	if not health.is_dead:
		body.modulate = Color.WHITE


func _on_died() -> void:
	body.modulate = Color(0.3, 0.3, 0.3, 1)
	await get_tree().create_timer(respawn_time).timeout
	health.reset()
	body.modulate = Color.WHITE
