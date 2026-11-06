extends CanvasLayer
## HUD ชั่วคราวสำหรับทดสอบ — แสดง HP, Stamina และ State ของผู้เล่น
## จะถูกแทนด้วย HUD จริงใน Task 6.2

const BAR_WIDTH: float = 80.0

@onready var hp_fill: ColorRect = $HpFill
@onready var st_fill: ColorRect = $StFill
@onready var info: Label = $Info


func _process(_delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return
	var hp_ratio: float = float(p.health.current_health) / p.health.max_health
	var st_ratio: float = p.stamina.current_stamina / p.stamina.max_stamina
	hp_fill.size.x = BAR_WIDTH * hp_ratio
	st_fill.size.x = BAR_WIDTH * st_ratio
	# Stamina ไม่พอโจมตี → แถบเป็นสีส้ม
	st_fill.color = Color(0.95, 0.85, 0.2) if p.stamina.has_enough(p.attack_stamina_cost) else Color(1, 0.45, 0.1)
	info.text = "HP %d/%d  ST %d/%d  %s" % [
		p.health.current_health, p.health.max_health,
		int(p.stamina.current_stamina), int(p.stamina.max_stamina),
		Player.State.keys()[p.state]]
