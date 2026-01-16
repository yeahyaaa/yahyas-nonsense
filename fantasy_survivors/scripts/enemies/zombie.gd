extends EnemyBase
class_name Zombie
## Zombie - Slow but tough undead enemy

func _ready() -> void:
	enemy_id = "zombie"
	enemy_name = "Zombie"
	max_health = 35.0
	move_speed = 50.0
	damage = 15.0
	attack_cooldown = 2.0
	xp_value = 2
	gold_value = 2
	super._ready()
