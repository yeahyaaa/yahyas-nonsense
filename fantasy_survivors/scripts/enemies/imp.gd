extends EnemyBase
class_name Imp
## Imp - Small demon, attacks from range

var shoot_range: float = 200.0
var projectile_speed: float = 200.0

func _ready() -> void:
	enemy_id = "imp"
	enemy_name = "Imp"
	max_health = 10.0
	move_speed = 70.0
	damage = 12.0
	attack_cooldown = 2.0
	xp_value = 2
	gold_value = 3
	super._ready()

func _handle_movement(delta: float) -> void:
	if is_attacking or not player:
		return

	var distance = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()

	# Keep distance for ranged attack
	if distance < shoot_range * 0.6:
		velocity = -direction * move_speed  # Back away
	elif distance > shoot_range:
		velocity = direction * move_speed  # Get closer
	else:
		velocity = Vector2.ZERO  # In range, stand still

	velocity += knockback_velocity

	if sprite and direction.x != 0:
		sprite.flip_h = direction.x < 0

func _handle_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer > 0:
		return

	var distance = global_position.distance_to(player.global_position)
	if distance <= shoot_range:
		_perform_attack()
		attack_timer = attack_cooldown

func _perform_attack() -> void:
	is_attacking = true

	# Spawn fireball
	var direction = (player.global_position - global_position).normalized()
	var fireball = Fireball.new()
	fireball.global_position = global_position
	fireball.direction = direction
	fireball.damage = damage
	fireball.speed = projectile_speed
	get_tree().current_scene.add_child(fireball)

	is_attacking = false


class Fireball extends Area2D:
	var direction: Vector2
	var damage: float
	var speed: float
	var lifetime: float = 4.0

	func _ready() -> void:
		collision_layer = 8  # Enemy projectile
		collision_mask = 1   # Player

		var shape = CircleShape2D.new()
		shape.radius = 6.0
		var collision = CollisionShape2D.new()
		collision.shape = shape
		add_child(collision)

		_create_visual()

		area_entered.connect(_on_hit)

		await get_tree().create_timer(lifetime).timeout
		queue_free()

	func _create_visual() -> void:
		var sprite = Polygon2D.new()
		sprite.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(0, -6), Vector2(6, 0), Vector2(0, 6)
		])
		sprite.color = Color(1.0, 0.4, 0.1)
		add_child(sprite)

	func _physics_process(delta: float) -> void:
		position += direction * speed * delta
		rotation += 5 * delta

	func _on_hit(area: Area2D) -> void:
		var target = area.get_parent()
		if target.has_method("take_damage"):
			target.take_damage(damage, self)
		queue_free()
