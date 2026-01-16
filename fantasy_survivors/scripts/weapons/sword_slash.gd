extends WeaponBase
class_name SwordSlash
## SwordSlash - Knight's starting weapon, melee arc attack

func _initialize_weapon() -> void:
	weapon_id = "sword_slash"
	weapon_name = "Sword Slash"
	description = "A wide melee arc that damages all enemies in front"
	base_damage = 15.0
	base_cooldown = 1.2
	base_projectile_count = 1
	base_area = 1.0
	base_knockback = 80.0

	damage_per_level = 4.0
	cooldown_reduction_per_level = 0.06
	extra_projectile_levels = [4, 7]  # Extra slash at levels 4 and 7

func _perform_attack() -> void:
	is_attacking = true
	attack_performed.emit()

	var direction = get_aim_direction()
	var projectile_count = get_projectile_count()

	for i in projectile_count:
		var angle_offset = 0.0
		if projectile_count > 1:
			angle_offset = (i - (projectile_count - 1) / 2.0) * 0.3  # Spread slashes

		var slash_dir = direction.rotated(angle_offset)
		_create_slash(slash_dir)

		if i < projectile_count - 1:
			await get_tree().create_timer(0.1).timeout

	is_attacking = false

func _create_slash(direction: Vector2) -> void:
	var slash = SlashHitbox.new()
	slash.global_position = player.global_position + direction * 30
	slash.direction = direction
	slash.damage = get_damage()
	slash.knockback = get_knockback()
	slash.arc_angle = deg_to_rad(90) * get_area()
	slash.range_distance = 60 * get_area()
	slash.duration = 0.2

	get_tree().current_scene.add_child(slash)


class SlashHitbox extends Area2D:
	var direction: Vector2
	var damage: float
	var knockback: float
	var arc_angle: float
	var range_distance: float
	var duration: float
	var enemies_hit: Array[Node] = []

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2

		# Create arc collision
		var shape = ConvexPolygonShape2D.new()
		var points: PackedVector2Array = []

		points.append(Vector2.ZERO)
		var segments = 8
		for i in range(segments + 1):
			var angle = -arc_angle / 2 + (arc_angle / segments) * i
			points.append(Vector2.from_angle(angle) * range_distance)

		shape.points = points

		var collision = CollisionShape2D.new()
		collision.shape = shape
		add_child(collision)

		rotation = direction.angle()

		# Visual effect
		_create_visual()

		area_entered.connect(_on_hit)
		body_entered.connect(_on_body_hit)

		await get_tree().create_timer(duration).timeout
		queue_free()

	func _create_visual() -> void:
		var polygon = Polygon2D.new()
		var points: PackedVector2Array = []

		points.append(Vector2.ZERO)
		var segments = 8
		for i in range(segments + 1):
			var angle = -arc_angle / 2 + (arc_angle / segments) * i
			points.append(Vector2.from_angle(angle) * range_distance)

		polygon.polygon = points
		polygon.color = Color(0.8, 0.8, 1.0, 0.6)
		add_child(polygon)

		# Fade out
		var tween = create_tween()
		tween.tween_property(polygon, "color:a", 0.0, duration)

	func _on_hit(area: Area2D) -> void:
		_try_damage(area.get_parent())

	func _on_body_hit(body: Node2D) -> void:
		_try_damage(body)

	func _try_damage(target: Node) -> void:
		if target in enemies_hit:
			return
		if target.has_method("take_damage"):
			target.take_damage(damage, self)
			enemies_hit.append(target)
		if target.has_method("apply_knockback"):
			target.apply_knockback(direction * knockback)
