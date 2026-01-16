extends WeaponBase
class_name ArrowVolley
## ArrowVolley - Archer's starting weapon, piercing arrows

func _initialize_weapon() -> void:
	weapon_id = "arrow_volley"
	weapon_name = "Arrow Volley"
	description = "Fast arrows that pierce through multiple enemies"
	base_damage = 8.0
	base_cooldown = 0.8
	base_projectile_count = 1
	base_projectile_speed = 450.0
	base_pierce = 3
	base_area = 1.0
	base_knockback = 20.0

	damage_per_level = 2.5
	cooldown_reduction_per_level = 0.04
	extra_projectile_levels = [2, 4, 6, 8]

func _perform_attack() -> void:
	is_attacking = true
	attack_performed.emit()

	var direction = get_aim_direction()
	var projectile_count = get_projectile_count()

	var spread_angle = deg_to_rad(15) * (projectile_count - 1)

	for i in projectile_count:
		var angle_offset = 0.0
		if projectile_count > 1:
			angle_offset = -spread_angle / 2 + (spread_angle / (projectile_count - 1)) * i

		var arrow_dir = direction.rotated(angle_offset)
		_create_arrow(arrow_dir)

	is_attacking = false

func _create_arrow(direction: Vector2) -> void:
	var arrow = Arrow.new()
	arrow.global_position = player.global_position
	arrow.direction = direction
	arrow.damage = get_damage()
	arrow.speed = base_projectile_speed
	arrow.pierce = get_pierce()
	arrow.knockback = get_knockback()

	get_tree().current_scene.add_child(arrow)


class Arrow extends Area2D:
	var direction: Vector2
	var damage: float
	var speed: float
	var pierce: int
	var knockback: float
	var lifetime: float = 3.0
	var enemies_hit: Array[Node] = []

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2

		var shape = CapsuleShape2D.new()
		shape.radius = 3.0
		shape.height = 16.0
		var collision = CollisionShape2D.new()
		collision.shape = shape
		collision.rotation = deg_to_rad(90)
		add_child(collision)

		_create_visual()
		rotation = direction.angle()

		area_entered.connect(_on_hit)

		await get_tree().create_timer(lifetime).timeout
		queue_free()

	func _create_visual() -> void:
		# Arrow shaft
		var shaft = Polygon2D.new()
		shaft.polygon = PackedVector2Array([
			Vector2(-12, -1.5),
			Vector2(4, -1.5),
			Vector2(4, 1.5),
			Vector2(-12, 1.5)
		])
		shaft.color = Color(0.6, 0.4, 0.2)
		add_child(shaft)

		# Arrow head
		var head = Polygon2D.new()
		head.polygon = PackedVector2Array([
			Vector2(4, -3),
			Vector2(12, 0),
			Vector2(4, 3)
		])
		head.color = Color(0.7, 0.7, 0.8)
		add_child(head)

		# Fletching
		var fletch = Polygon2D.new()
		fletch.polygon = PackedVector2Array([
			Vector2(-12, 0),
			Vector2(-16, -4),
			Vector2(-14, 0),
			Vector2(-16, 4)
		])
		fletch.color = Color(0.8, 0.2, 0.2)
		add_child(fletch)

	func _physics_process(delta: float) -> void:
		position += direction * speed * delta

	func _on_hit(area: Area2D) -> void:
		var target = area.get_parent()
		if target in enemies_hit:
			return
		if target.has_method("take_damage"):
			target.take_damage(damage, self)
			enemies_hit.append(target)
		if target.has_method("apply_knockback"):
			target.apply_knockback(direction * knockback)

		pierce -= 1
		if pierce <= 0:
			queue_free()
