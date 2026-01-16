extends CharacterBody2D
class_name EnemyBase
## EnemyBase - Base class for all enemies

signal enemy_died(enemy: EnemyBase, is_elite: bool)
signal enemy_damaged(current_health: float, max_health: float)

@export var enemy_id: String = "base_enemy"
@export var enemy_name: String = "Enemy"
@export var sprite: Sprite2D
@export var hitbox: Area2D
@export var health_bar: ProgressBar

# Base stats
@export var max_health: float = 20.0
@export var move_speed: float = 80.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var xp_value: int = 1
@export var gold_value: int = 1

# Elite modifiers
var is_elite: bool = false
var elite_health_mult: float = 5.0
var elite_damage_mult: float = 2.0
var elite_size_mult: float = 1.5
var elite_xp_mult: float = 10.0
var elite_gold_mult: float = 5.0
var chest_drop_chance: float = 0.3  # 30% chance for elites to drop chest

# Current state
var current_health: float
var attack_timer: float = 0.0
var is_attacking: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var player: Node2D

# Visual
var damage_flash_tween: Tween

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	current_health = max_health

	if is_elite:
		_apply_elite_modifiers()

	_setup_hitbox()
	_update_health_bar()

func _setup_hitbox() -> void:
	if hitbox:
		hitbox.collision_layer = 2  # Enemy layer
		hitbox.collision_mask = 4   # Player projectiles
		hitbox.area_entered.connect(_on_hitbox_entered)

func _apply_elite_modifiers() -> void:
	max_health *= elite_health_mult
	current_health = max_health
	damage *= elite_damage_mult
	xp_value = int(xp_value * elite_xp_mult)
	gold_value = int(gold_value * elite_gold_mult)

	if sprite:
		sprite.scale *= elite_size_mult
		sprite.modulate = Color(1.2, 0.8, 0.3)  # Golden tint

	# Make collision bigger too
	scale *= elite_size_mult

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	_handle_movement(delta)
	_handle_attack(delta)
	_process_knockback(delta)
	move_and_slide()

func _handle_movement(delta: float) -> void:
	if is_attacking:
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed + knockback_velocity

	# Face movement direction
	if sprite and direction.x != 0:
		sprite.flip_h = direction.x < 0

func _handle_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer > 0:
		return

	# Check if close enough to attack
	var distance = global_position.distance_to(player.global_position)
	if distance < 40:  # Melee range
		_perform_attack()
		attack_timer = attack_cooldown

func _perform_attack() -> void:
	if player.has_method("take_damage"):
		player.take_damage(damage, self)

func _process_knockback(delta: float) -> void:
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)

func apply_knockback(force: Vector2) -> void:
	knockback_velocity += force

func take_damage(amount: float, source: Node = null) -> void:
	current_health -= amount
	enemy_damaged.emit(current_health, max_health)
	_update_health_bar()
	_flash_damage()

	if current_health <= 0:
		_die()

func _flash_damage() -> void:
	if sprite:
		if damage_flash_tween:
			damage_flash_tween.kill()
		damage_flash_tween = create_tween()
		damage_flash_tween.tween_property(sprite, "modulate", Color(1.5, 0.5, 0.5), 0.05)
		damage_flash_tween.tween_property(sprite, "modulate", Color.WHITE if not is_elite else Color(1.2, 0.8, 0.3), 0.1)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health / max_health * 100
		health_bar.visible = current_health < max_health

func _die() -> void:
	enemy_died.emit(self, is_elite)

	# Drop XP gem
	_spawn_xp_gem()

	# Drop gold
	if randf() < 0.3 or is_elite:  # 30% chance or always for elites
		_spawn_gold()

	# Elite chest drop
	if is_elite and randf() < chest_drop_chance:
		_spawn_chest()

	PlayerStats.add_kill()
	queue_free()

func _spawn_xp_gem() -> void:
	var gem_scene = load("res://scenes/pickups/xp_gem.tscn")
	if gem_scene:
		var gem = gem_scene.instantiate()
		gem.global_position = global_position
		gem.xp_value = xp_value
		get_tree().current_scene.add_child(gem)

func _spawn_gold() -> void:
	var gold_scene = load("res://scenes/pickups/gold.tscn")
	if gold_scene:
		var gold = gold_scene.instantiate()
		gold.global_position = global_position
		gold.gold_value = gold_value
		get_tree().current_scene.add_child(gold)

func _spawn_chest() -> void:
	var chest_scene = load("res://scenes/pickups/chest.tscn")
	if chest_scene:
		var chest = chest_scene.instantiate()
		chest.global_position = global_position
		get_tree().current_scene.add_child(chest)

func _on_hitbox_entered(area: Area2D) -> void:
	# Usually handled by projectiles hitting us
	pass

# For scaling with game time
func scale_stats(multiplier: float) -> void:
	max_health *= multiplier
	current_health = max_health
	damage *= multiplier
	xp_value = int(xp_value * multiplier)
	gold_value = int(gold_value * multiplier)
