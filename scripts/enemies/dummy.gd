class_name Dummy
extends StaticBody2D
## หุ่นฝึก — เป้าทดสอบการโจมตี ไม่ขยับ ไม่ตีกลับ
## ถูกตีจนหมด HP แล้วจะฟื้นเองหลัง 1 วินาที

@export var respawn_time: float = 1.0

@onready var health: HealthComponent = $HealthComponent
@onready var body: ColorRect = $ColorRect

var _base_color: Color


func _ready() -> void:
	_base_color = body.color
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _on_damaged(amount: int) -> void:
	print("Dummy โดน %d  เหลือ %d" % [amount, health.current_health])
	# กระพริบขาวสั้น ๆ ให้รู้ว่าโดน
	body.color = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if not health.is_dead:
		body.color = _base_color


func _on_died() -> void:
	body.color = Color(0.3, 0.3, 0.3)
	await get_tree().create_timer(respawn_time).timeout
	health.reset()
	body.color = _base_color
