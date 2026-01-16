extends Node2D
class_name WeaponBase
## WeaponBase - Base class for all weapons with auto-attack functionality

signal weapon_upgraded(new_level: int)
signal attack_performed

@export var weapon_id: String = "base_weapon"
@export var weapon_name: String = "Base Weapon"
@export var description: String = "A basic weapon"
@export var icon: Texture2D

# Base stats (level 1)
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0
@export var base_projectile_count: int = 1
@export var base_projectile_speed: float = 300.0
@export var base_pierce: int = 1
@export var base_area: float = 1.0
@export var base_duration: float = 0.0
@export var base_knockback: float = 50.0

# Scaling per level
@export var damage_per_level: float = 3.0
@export var cooldown_reduction_per_level: float = 0.05
@export var extra_projectile_levels: Array[int] = [3, 6]  # Levels that add projectiles

# Current state
var level: int = 1
var max_level: int = 8
var cooldown_timer: float = 0.0
var is_attacking: bool = false

# Cached player reference
var player: Player

# Projectile scene (override in subclass)
var projectile_scene: PackedScene

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	_initialize_weapon()

func _initialize_weapon() -> void:
	# Override in subclass for specific initialization
	pass

func _process(delta: float) -> void:
	if not player or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	cooldown_timer -= delta
	if cooldown_timer <= 0:
		_perform_attack()
		cooldown_timer = get_cooldown()

func _perform_attack() -> void:
	# Override in subclass
	is_attacking = true
	attack_performed.emit()
	is_attacking = false

func get_damage() -> float:
	var base = base_damage + (damage_per_level * (level - 1))
	return base * PlayerStats.get_stat("damage") / 10.0  # Normalize with player damage stat

func get_cooldown() -> float:
	var reduction = 1.0 - (cooldown_reduction_per_level * (level - 1))
	var attack_speed = PlayerStats.get_stat("attack_speed")
	return base_cooldown * reduction / attack_speed

func get_projectile_count() -> int:
	var count = base_projectile_count
	for lvl in extra_projectile_levels:
		if level >= lvl:
			count += 1
	return count

func get_pierce() -> int:
	return base_pierce + int(level / 3)

func get_area() -> float:
	return base_area * (1.0 + (level - 1) * 0.1)

func get_knockback() -> float:
	return base_knockback * (1.0 + (level - 1) * 0.1)

func upgrade() -> bool:
	if level >= max_level:
		return false
	level += 1
	weapon_upgraded.emit(level)
	return true

func get_stats_text() -> String:
	return "DMG: %.0f | CD: %.1fs | Count: %d" % [get_damage(), get_cooldown(), get_projectile_count()]

func spawn_projectile(direction: Vector2, offset: Vector2 = Vector2.ZERO) -> Node2D:
	if not projectile_scene:
		return null

	var projectile = projectile_scene.instantiate()
	projectile.global_position = player.global_position + offset
	projectile.direction = direction.normalized()
	projectile.damage = get_damage()
	projectile.speed = base_projectile_speed
	projectile.pierce = get_pierce()
	projectile.knockback = get_knockback()
	projectile.area_scale = get_area()

	get_tree().current_scene.add_child(projectile)
	return projectile

func get_aim_direction() -> Vector2:
	return player.aim_direction if player else Vector2.RIGHT
