extends EnemyBase
class_name Skeleton
## Skeleton - Basic undead enemy, fast but fragile

func _ready() -> void:
	enemy_id = "skeleton"
	enemy_name = "Skeleton"
	max_health = 15.0
	move_speed = 100.0
	damage = 8.0
	attack_cooldown = 1.2
	xp_value = 1
	gold_value = 1
	super._ready()
