extends WeaponBase
class_name MagicMissile
## MagicMissile - Mage's starting weapon, homing projectiles

func _initialize_weapon() -> void:
	weapon_id = "magic_missile"
	weapon_name = "Magic Missile"
	description = "Homing magical projectiles that seek out enemies"
	base_damage = 12.0
	base_cooldown = 1.5
	base_projectile_count = 1
	base_projectile_speed = 250.0
	base_pierce = 1
	base_area = 1.0
	base_knockback = 30.0

	damage_per_level = 3.0
	cooldown_reduction_per_level = 0.05
	extra_projectile_levels = [2, 4, 6]  # More missiles at these levels

func _perform_attack() -> void:
	is_attacking = true
	attack_performed.emit()

	var direction = get_aim_direction()
	var projectile_count = get_projectile_count()

	for i in projectile_count:
		var angle_offset = 0.0
		if projectile_count > 1:
			angle_offset = (randf() - 0.5) * 0.8  # Random spread

		var missile_dir = direction.rotated(angle_offset)
		_create_missile(missile_dir)

		await get_tree().create_timer(0.08).timeout

	is_attacking = false

func _create_missile(direction: Vector2) -> void:
	var missile = HomingMissile.new()
	missile.global_position = player.global_position
	missile.direction = direction
	missile.damage = get_damage()
	missile.speed = base_projectile_speed
	missile.pierce = get_pierce()
	missile.knockback = get_knockback()
	missile.homing_strength = 3.0 + level * 0.5

	get_tree().current_scene.add_child(missile)


class HomingMissile extends Area2D:
	var direction: Vector2
	var damage: float
	var speed: float
	var pierce: int
	var knockback: float
	var homing_strength: float = 3.0
	var lifetime: float = 4.0
	var enemies_hit: Array[Node] = []
	var target: Node2D = null

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2

		# Collision shape
		var shape = CircleShape2D.new()
		shape.radius = 8.0
		var collision = CollisionShape2D.new()
		collision.shape = shape
		add_child(collision)

		# Visual
		_create_visual()

		area_entered.connect(_on_hit)

		await get_tree().create_timer(lifetime).timeout
		queue_free()

	func _create_visual() -> void:
		var sprite = Polygon2D.new()
		sprite.polygon = PackedVector2Array([
			Vector2(-8, -4),
			Vector2(8, 0),
			Vector2(-8, 4),
			Vector2(-4, 0)
		])
		sprite.color = Color(0.4, 0.6, 1.0, 0.9)
		add_child(sprite)

		# Glow effect
		var glow = Polygon2D.new()
		glow.polygon = sprite.polygon
		glow.scale = Vector2(1.3, 1.3)
		glow.color = Color(0.6, 0.8, 1.0, 0.3)
		add_child(glow)
		glow.z_index = -1

	func _physics_process(delta: float) -> void:
		# Find nearest enemy if no target
		if not is_instance_valid(target):
			target = _find_nearest_enemy()

		# Home towards target
		if is_instance_valid(target):
			var to_target = (target.global_position - global_position).normalized()
			direction = direction.lerp(to_target, homing_strength * delta).normalized()

		# Move
		position += direction * speed * delta
		rotation = direction.angle()

	func _find_nearest_enemy() -> Node2D:
		var enemies = get_tree().get_nodes_in_group("enemies")
		var nearest: Node2D = null
		var nearest_dist: float = INF

		for enemy in enemies:
			if enemy in enemies_hit:
				continue
			var dist = global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy

		return nearest

	func _on_hit(area: Area2D) -> void:
		var target_node = area.get_parent()
		if target_node in enemies_hit:
			return
		if target_node.has_method("take_damage"):
			target_node.take_damage(damage, self)
			enemies_hit.append(target_node)
		if target_node.has_method("apply_knockback"):
			target_node.apply_knockback(direction * knockback)

		pierce -= 1
		if pierce <= 0:
			_explode()
			queue_free()

	func _explode() -> void:
		# Small explosion effect
		var explosion = Polygon2D.new()
		explosion.polygon = PackedVector2Array([
			Vector2(-12, 0), Vector2(0, -12), Vector2(12, 0), Vector2(0, 12)
		])
		explosion.color = Color(0.6, 0.8, 1.0, 0.8)
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)

		var tween = explosion.create_tween()
		tween.parallel().tween_property(explosion, "scale", Vector2(2, 2), 0.2)
		tween.parallel().tween_property(explosion, "color:a", 0.0, 0.2)
		tween.tween_callback(explosion.queue_free)
