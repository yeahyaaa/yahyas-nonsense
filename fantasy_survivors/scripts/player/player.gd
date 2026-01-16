extends CharacterBody2D
class_name Player
## Player - Main player controller with twin-stick controls

signal weapon_fired(weapon_data: Dictionary)
signal player_died

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer
@export var weapon_container: Node2D
@export var hitbox: Area2D
@export var pickup_area: Area2D

# Movement
var move_direction: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT
var is_moving: bool = false

# Combat
var weapons: Array[Node] = []
var invincible: bool = false
var invincibility_timer: float = 0.0
const INVINCIBILITY_DURATION: float = 0.5

# Visual
var facing_right: bool = true
var flash_tween: Tween

func _ready() -> void:
	add_to_group("player")
	_setup_hitbox()
	_setup_pickup_area()
	_connect_signals()
	_initialize_starting_weapon()

func _setup_hitbox() -> void:
	if hitbox:
		hitbox.collision_layer = 1  # Player layer
		hitbox.collision_mask = 2 | 4  # Enemy + enemy projectiles

func _setup_pickup_area() -> void:
	if pickup_area:
		pickup_area.collision_layer = 0
		pickup_area.collision_mask = 32  # Pickups layer
		pickup_area.area_entered.connect(_on_pickup_collected)

func _connect_signals() -> void:
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.level_up.connect(_on_level_up)

func _initialize_starting_weapon() -> void:
	var class_data = PlayerStats.get_class_data()
	var weapon_id = class_data["starting_weapon"]
	add_weapon(weapon_id)

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_aim()
	_update_invincibility(delta)
	_regenerate_health(delta)
	move_and_slide()

func _handle_movement(delta: float) -> void:
	var speed = PlayerStats.get_stat("move_speed")
	velocity = move_direction * speed
	is_moving = move_direction.length() > 0.1

	# Update facing direction
	if move_direction.x != 0:
		facing_right = move_direction.x > 0
		if sprite:
			sprite.flip_h = not facing_right

func _handle_aim() -> void:
	# Aim direction is set by virtual joystick
	# If no aim input, aim in move direction
	if aim_direction.length() < 0.1:
		if move_direction.length() > 0.1:
			aim_direction = move_direction.normalized()
		else:
			aim_direction = Vector2.RIGHT if facing_right else Vector2.LEFT

func _update_invincibility(delta: float) -> void:
	if invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			invincible = false
			_stop_flash()

func _regenerate_health(delta: float) -> void:
	var regen = PlayerStats.get_stat("health_regen")
	if regen > 0 and PlayerStats.current_health < PlayerStats.get_stat("max_health"):
		PlayerStats.heal(regen * delta)

func set_move_input(direction: Vector2) -> void:
	move_direction = direction.normalized() if direction.length() > 1.0 else direction

func set_aim_input(direction: Vector2) -> void:
	if direction.length() > 0.1:
		aim_direction = direction.normalized()

func take_damage(amount: float, source: Node = null) -> void:
	if invincible:
		return

	PlayerStats.take_damage(amount)
	_start_invincibility()
	_flash_damage()

	if PlayerStats.current_health <= 0:
		_die()

func _start_invincibility() -> void:
	invincible = true
	invincibility_timer = INVINCIBILITY_DURATION

func _flash_damage() -> void:
	if sprite:
		if flash_tween:
			flash_tween.kill()
		flash_tween = create_tween()
		flash_tween.set_loops(3)
		flash_tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 0.7), 0.08)
		flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)

func _stop_flash() -> void:
	if sprite:
		sprite.modulate = Color.WHITE
	if flash_tween:
		flash_tween.kill()

func _die() -> void:
	player_died.emit()
	PlayerStats.end_run()
	# Death animation handled by game scene

func add_weapon(weapon_id: String, level: int = 1) -> void:
	# Check if weapon already exists
	for weapon in weapons:
		if weapon.weapon_id == weapon_id:
			weapon.upgrade()
			return

	# Create new weapon
	var weapon_scene = load("res://scenes/weapons/%s.tscn" % weapon_id)
	if weapon_scene:
		var weapon = weapon_scene.instantiate()
		weapon.level = level
		weapon_container.add_child(weapon)
		weapons.append(weapon)

func upgrade_weapon(weapon_id: String) -> bool:
	for weapon in weapons:
		if weapon.weapon_id == weapon_id:
			return weapon.upgrade()
	return false

func get_weapon(weapon_id: String) -> Node:
	for weapon in weapons:
		if weapon.weapon_id == weapon_id:
			return weapon
	return null

func get_all_weapons() -> Array:
	return weapons

func _on_pickup_collected(area: Area2D) -> void:
	if area.has_method("collect"):
		area.collect(self)

func _on_health_changed(current: float, maximum: float) -> void:
	# Update health bar or trigger UI effects
	pass

func _on_level_up(new_level: int) -> void:
	# Trigger level up UI/effects
	# Pause game and show upgrade choices
	GameManager.pause_game()
	# Level up UI will handle the rest
