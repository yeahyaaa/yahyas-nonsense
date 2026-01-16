extends EnemyBase
class_name Goblin
## Goblin - Fast, weak monster

func _ready() -> void:
	enemy_id = "goblin"
	enemy_name = "Goblin"
	max_health = 12.0
	move_speed = 120.0
	damage = 6.0
	attack_cooldown = 0.8
	xp_value = 1
	gold_value = 2
	super._ready()
