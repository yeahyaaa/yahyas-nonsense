extends Node2D
class_name EnemySpawner

var player: Node2D
var spawn_timer: float = 0.0
var elite_timer: float = 0.0
var enemy_count: int = 0
const MAX_ENEMIES: int = 150
const SPAWN_RADIUS_MIN: float = 400.0
const SPAWN_RADIUS_MAX: float = 600.0
const ELITE_INTERVAL: float = 30.0

# Enemy types by stage theme
var enemy_pools: Dictionary = {
	1: [  # Undead
		{"type": "skeleton", "health": 15, "speed": 100, "damage": 8, "xp": 1, "gold": 1, "weight": 10, "min_time": 0},
		{"type": "zombie", "health": 35, "speed": 50, "damage": 15, "xp": 2, "gold": 2, "weight": 5, "min_time": 30},
	],
	2: [  # Monsters
		{"type": "goblin", "health": 12, "speed": 120, "damage": 6, "xp": 1, "gold": 2, "weight": 10, "min_time": 0},
		{"type": "orc", "health": 50, "speed": 60, "damage": 18, "xp": 3, "gold": 3, "weight": 4, "min_time": 45},
	],
	3: [  # Demons
		{"type": "imp", "health": 10, "speed": 90, "damage": 12, "xp": 2, "gold": 2, "weight": 10, "min_time": 0},
		{"type": "demon", "health": 80, "speed": 70, "damage": 25, "xp": 5, "gold": 5, "weight": 3, "min_time": 60},
	]
}

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if Global.state != Global.State.PLAYING:
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	_handle_spawning(delta)
	_handle_elite_spawning(delta)
	_handle_pickup_magnetism()

func _handle_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0 and enemy_count < MAX_ENEMIES:
		var count = _get_spawn_count()
		for i in count:
			_spawn_enemy(false)
		spawn_timer = _get_spawn_interval()

func _handle_elite_spawning(delta: float) -> void:
	elite_timer += delta
	if elite_timer >= ELITE_INTERVAL:
		_spawn_enemy(true)
		elite_timer = 0.0

func _get_spawn_count() -> int:
	return 2 + int(Global.game_time / 30)

func _get_spawn_interval() -> float:
	return max(0.3, 1.5 - Global.game_time / 300)

func _spawn_enemy(is_elite: bool) -> void:
	var pool = enemy_pools.get(Global.current_stage, enemy_pools[1])
	var available = pool.filter(func(e): return Global.game_time >= e["min_time"])
	if available.is_empty():
		available = [pool[0]]

	var data = _weighted_random(available)

	var enemy = Enemy.new()
	enemy.enemy_type = data["type"]
	enemy.max_health = data["health"]
	enemy.move_speed = data["speed"]
	enemy.damage = data["damage"]
	enemy.xp_value = data["xp"]
	enemy.gold_value = data["gold"]
	enemy.is_elite = is_elite
	enemy.scale_to_time(Global.game_time)

	enemy.global_position = _get_spawn_position()
	enemy.died.connect(_on_enemy_died)

	add_child(enemy)
	enemy_count += 1

func _get_spawn_position() -> Vector2:
	var angle = randf() * TAU
	var dist = randf_range(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
	return player.global_position + Vector2.from_angle(angle) * dist

func _weighted_random(pool: Array) -> Dictionary:
	var total = 0
	for item in pool:
		total += item["weight"]
	var roll = randf() * total
	var cumulative = 0
	for item in pool:
		cumulative += item["weight"]
		if roll <= cumulative:
			return item
	return pool[0]

func _on_enemy_died(enemy: Enemy) -> void:
	enemy_count -= 1

func _handle_pickup_magnetism() -> void:
	var pickups = get_tree().get_nodes_in_group("pickups")
	for pickup in pickups:
		if pickup.has_method("magnetize"):
			var dist = player.global_position.distance_to(pickup.global_position)
			if dist <= Global.pickup_range:
				pickup.magnetize(player)
