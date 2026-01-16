extends CharacterBody2D
class_name Player

signal died

# Movement
var move_dir: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT
var facing_right: bool = true

# Combat
var invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_TIME: float = 0.5

# Weapons
var weapons: Array[Node] = []

# Nodes
@onready var sprite: Polygon2D = $Sprite
@onready var shadow: Polygon2D = $Shadow
@onready var weapon_container: Node2D = $Weapons
@onready var pickup_area: Area2D = $PickupArea

func _ready() -> void:
	add_to_group("player")
	_create_visuals()
	_setup_weapons()

	# Connect pickup area
	pickup_area.area_entered.connect(_on_pickup_entered)

func _create_visuals() -> void:
	# Body
	sprite.polygon = PackedVector2Array([
		Vector2(-12, -20), Vector2(12, -20),
		Vector2(14, 15), Vector2(-14, 15)
	])
	sprite.color = Color(0.3, 0.4, 0.7)

	# Head
	var head = Polygon2D.new()
	head.polygon = _circle_points(10, 12)
	head.position = Vector2(0, -28)
	head.color = Color(0.9, 0.75, 0.65)
	sprite.add_child(head)

	# Shadow
	shadow.polygon = _circle_points(14, 8)
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(0, 18)

func _circle_points(radius: float, segments: int = 16) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i in segments:
		var angle = i * TAU / segments
		points.append(Vector2.from_angle(angle) * radius)
	return points

func _setup_weapons() -> void:
	# Clear existing
	for child in weapon_container.get_children():
		child.queue_free()
	weapons.clear()

	# Add weapons based on Global.player_weapons
	for weapon_id in Global.player_weapons:
		_add_weapon(weapon_id, Global.player_weapons[weapon_id])

func _add_weapon(weapon_id: String, level: int) -> void:
	var weapon: Node2D
	match weapon_id:
		"sword": weapon = SwordWeapon.new()
		"magic": weapon = MagicWeapon.new()
		"arrow": weapon = ArrowWeapon.new()
		"fire_orbit": weapon = FireOrbitWeapon.new()
		"lightning": weapon = LightningWeapon.new()
		"holy": weapon = HolyWeapon.new()
		_: return

	weapon.level = level
	weapon.player = self
	weapon_container.add_child(weapon)
	weapons.append(weapon)

func _physics_process(delta: float) -> void:
	if Global.state != Global.State.PLAYING:
		return

	_handle_input()
	_handle_movement(delta)
	_handle_invincibility(delta)
	_handle_regen(delta)
	move_and_slide()

func _handle_input() -> void:
	# Keyboard input (for PC testing)
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"): input_dir.x -= 1
	if Input.is_action_pressed("move_right"): input_dir.x += 1
	if Input.is_action_pressed("move_up"): input_dir.y -= 1
	if Input.is_action_pressed("move_down"): input_dir.y += 1

	if input_dir.length() > 0:
		move_dir = input_dir.normalized()

	# Update aim direction
	if move_dir.length() > 0.1:
		aim_dir = move_dir.normalized()

func _handle_movement(delta: float) -> void:
	velocity = move_dir * Global.move_speed

	# Update facing
	if move_dir.x != 0:
		facing_right = move_dir.x > 0
		sprite.scale.x = 1 if facing_right else -1

func _handle_invincibility(delta: float) -> void:
	if invincible:
		invincible_timer -= delta
		sprite.modulate.a = 0.5 if int(invincible_timer * 10) % 2 == 0 else 1.0
		if invincible_timer <= 0:
			invincible = false
			sprite.modulate.a = 1.0

func _handle_regen(delta: float) -> void:
	if Global.health_regen > 0 and Global.current_health < Global.max_health:
		Global.heal(Global.health_regen * delta)

func set_move_input(direction: Vector2) -> void:
	move_dir = direction

func set_aim_input(direction: Vector2) -> void:
	if direction.length() > 0.1:
		aim_dir = direction.normalized()

func take_damage(amount: float) -> void:
	if invincible:
		return

	Global.take_damage(amount)
	invincible = true
	invincible_timer = INVINCIBLE_TIME

	# Flash red
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		sprite.modulate = Color.WHITE

func refresh_weapons() -> void:
	_setup_weapons()

func _on_pickup_entered(area: Area2D) -> void:
	if area.has_method("collect"):
		area.collect()


# ============ WEAPON CLASSES ============

class WeaponBase extends Node2D:
	var level: int = 1
	var player: Player
	var cooldown: float = 1.0
	var timer: float = 0.0

	func _process(delta: float) -> void:
		if Global.state != Global.State.PLAYING:
			return
		timer -= delta
		if timer <= 0:
			attack()
			timer = cooldown / Global.attack_speed

	func attack() -> void:
		pass

	func get_damage() -> float:
		return (10 + level * 3) * Global.damage_mult

	func is_crit() -> bool:
		return randf() < Global.crit_chance


class SwordWeapon extends WeaponBase:
	func _init() -> void:
		cooldown = 1.0

	func attack() -> void:
		var slash = SwordSlash.new()
		slash.damage = get_damage()
		slash.crit = is_crit()
		slash.direction = player.aim_dir
		slash.position = player.global_position + player.aim_dir * 30
		slash.scale_factor = 1.0 + level * 0.15
		player.get_parent().add_child(slash)

		# Extra slashes at higher levels
		if level >= 4:
			await player.get_tree().create_timer(0.15).timeout
			if is_instance_valid(player):
				var slash2 = SwordSlash.new()
				slash2.damage = get_damage()
				slash2.direction = player.aim_dir.rotated(0.3)
				slash2.position = player.global_position + slash2.direction * 30
				slash2.scale_factor = 1.0 + level * 0.15
				player.get_parent().add_child(slash2)

		if level >= 7:
			await player.get_tree().create_timer(0.15).timeout
			if is_instance_valid(player):
				var slash3 = SwordSlash.new()
				slash3.damage = get_damage()
				slash3.direction = player.aim_dir.rotated(-0.3)
				slash3.position = player.global_position + slash3.direction * 30
				slash3.scale_factor = 1.0 + level * 0.15
				player.get_parent().add_child(slash3)


class MagicWeapon extends WeaponBase:
	func _init() -> void:
		cooldown = 1.2

	func attack() -> void:
		var count = 1 + int(level / 2)
		for i in count:
			var missile = MagicMissile.new()
			missile.damage = get_damage()
			missile.crit = is_crit()
			missile.position = player.global_position
			missile.direction = player.aim_dir.rotated(randf_range(-0.3, 0.3))
			player.get_parent().add_child(missile)
			await player.get_tree().create_timer(0.1).timeout


class ArrowWeapon extends WeaponBase:
	func _init() -> void:
		cooldown = 0.7

	func attack() -> void:
		var count = 1 + int(level / 2)
		var spread = deg_to_rad(10) * (count - 1)

		for i in count:
			var arrow = Arrow.new()
			arrow.damage = get_damage()
			arrow.crit = is_crit()
			arrow.pierce = 2 + int(level / 3)
			arrow.position = player.global_position

			var angle_offset = 0.0
			if count > 1:
				angle_offset = -spread/2 + spread * i / (count - 1)
			arrow.direction = player.aim_dir.rotated(angle_offset)
			player.get_parent().add_child(arrow)


class FireOrbitWeapon extends WeaponBase:
	var orbs: Array[Node2D] = []

	func _init() -> void:
		cooldown = 0.1  # Constant orbit

	func _ready() -> void:
		_create_orbs()

	func _create_orbs() -> void:
		for orb in orbs:
			if is_instance_valid(orb):
				orb.queue_free()
		orbs.clear()

		var count = 2 + int(level / 2)
		for i in count:
			var orb = FireOrb.new()
			orb.damage = get_damage() * 0.5
			orb.orbit_index = i
			orb.orbit_count = count
			orbs.append(orb)
			player.add_child(orb)

	func attack() -> void:
		if orbs.size() != 2 + int(level / 2):
			_create_orbs()


class LightningWeapon extends WeaponBase:
	func _init() -> void:
		cooldown = 2.0

	func attack() -> void:
		var enemies = player.get_tree().get_nodes_in_group("enemies")
		if enemies.is_empty():
			return

		enemies.shuffle()
		var targets = enemies.slice(0, min(level, enemies.size()))

		for enemy in targets:
			var bolt = LightningBolt.new()
			bolt.damage = get_damage() * 1.5
			bolt.crit = is_crit()
			bolt.start_pos = player.global_position + Vector2(0, -50)
			bolt.end_pos = enemy.global_position
			player.get_parent().add_child(bolt)
			await player.get_tree().create_timer(0.1).timeout


class HolyWeapon extends WeaponBase:
	func _init() -> void:
		cooldown = 3.0

	func attack() -> void:
		var holy = HolySmite.new()
		holy.damage = get_damage() * 2.0
		holy.crit = is_crit()
		holy.position = player.global_position
		holy.radius = 80 + level * 15
		player.get_parent().add_child(holy)


# ============ PROJECTILE CLASSES ============

class SwordSlash extends Area2D:
	var damage: float = 10.0
	var crit: bool = false
	var direction: Vector2 = Vector2.RIGHT
	var scale_factor: float = 1.0
	var hit_enemies: Array = []

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2
		rotation = direction.angle()

		# Visual
		var poly = Polygon2D.new()
		var points: PackedVector2Array = []
		points.append(Vector2.ZERO)
		for i in 9:
			var angle = -PI/3 + (2*PI/3) * i / 8
			points.append(Vector2.from_angle(angle) * 50 * scale_factor)
		poly.polygon = points
		poly.color = Color(0.8, 0.8, 0.95, 0.7) if not crit else Color(1.0, 0.8, 0.3, 0.8)
		add_child(poly)

		# Collision
		var shape = ConvexPolygonShape2D.new()
		shape.points = points
		var col = CollisionShape2D.new()
		col.shape = shape
		add_child(col)

		area_entered.connect(_on_hit)

		# Animate and destroy
		var tween = create_tween()
		tween.tween_property(poly, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)

	func _on_hit(area: Area2D) -> void:
		var enemy = area.get_parent()
		if enemy in hit_enemies:
			return
		hit_enemies.append(enemy)
		if enemy.has_method("take_damage"):
			var final_damage = damage * (Global.crit_damage if crit else 1.0)
			enemy.take_damage(final_damage, direction)


class MagicMissile extends Area2D:
	var damage: float = 10.0
	var crit: bool = false
	var direction: Vector2 = Vector2.RIGHT
	var speed: float = 300.0
	var homing: float = 5.0
	var target: Node2D = null
	var lifetime: float = 4.0

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2

		# Visual
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-8, -4), Vector2(8, 0), Vector2(-8, 4), Vector2(-4, 0)
		])
		poly.color = Color(0.4, 0.5, 0.95) if not crit else Color(1.0, 0.8, 0.3)
		add_child(poly)

		# Glow
		var glow = Polygon2D.new()
		glow.polygon = poly.polygon
		glow.color = Color(0.5, 0.6, 1.0, 0.3)
		glow.scale = Vector2(1.5, 1.5)
		glow.z_index = -1
		add_child(glow)

		# Collision
		var shape = CircleShape2D.new()
		shape.radius = 8
		var col = CollisionShape2D.new()
		col.shape = shape
		add_child(col)

		area_entered.connect(_on_hit)

		await get_tree().create_timer(lifetime).timeout
		queue_free()

	func _physics_process(delta: float) -> void:
		# Find target
		if not is_instance_valid(target):
			var enemies = get_tree().get_nodes_in_group("enemies")
			var nearest_dist = INF
			for enemy in enemies:
				var dist = global_position.distance_to(enemy.global_position)
				if dist < nearest_dist:
					nearest_dist = dist
					target = enemy

		# Home toward target
		if is_instance_valid(target):
			var to_target = (target.global_position - global_position).normalized()
			direction = direction.lerp(to_target, homing * delta).normalized()

		position += direction * speed * delta
		rotation = direction.angle()

	func _on_hit(area: Area2D) -> void:
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			var final_damage = damage * (Global.crit_damage if crit else 1.0)
			enemy.take_damage(final_damage, direction)
		queue_free()


class Arrow extends Area2D:
	var damage: float = 10.0
	var crit: bool = false
	var direction: Vector2 = Vector2.RIGHT
	var speed: float = 500.0
	var pierce: int = 2
	var hit_enemies: Array = []
	var lifetime: float = 3.0

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2
		rotation = direction.angle()

		# Visual - arrow shape
		var shaft = Polygon2D.new()
		shaft.polygon = PackedVector2Array([
			Vector2(-15, -2), Vector2(5, -2), Vector2(5, 2), Vector2(-15, 2)
		])
		shaft.color = Color(0.55, 0.35, 0.2)
		add_child(shaft)

		var head = Polygon2D.new()
		head.polygon = PackedVector2Array([
			Vector2(5, -4), Vector2(15, 0), Vector2(5, 4)
		])
		head.color = Color(0.7, 0.7, 0.8) if not crit else Color(1.0, 0.8, 0.3)
		add_child(head)

		# Collision
		var shape = CapsuleShape2D.new()
		shape.radius = 4
		shape.height = 20
		var col = CollisionShape2D.new()
		col.shape = shape
		col.rotation = PI/2
		add_child(col)

		area_entered.connect(_on_hit)

		await get_tree().create_timer(lifetime).timeout
		queue_free()

	func _physics_process(delta: float) -> void:
		position += direction * speed * delta

	func _on_hit(area: Area2D) -> void:
		var enemy = area.get_parent()
		if enemy in hit_enemies:
			return
		hit_enemies.append(enemy)

		if enemy.has_method("take_damage"):
			var final_damage = damage * (Global.crit_damage if crit else 1.0)
			enemy.take_damage(final_damage, direction)

		pierce -= 1
		if pierce <= 0:
			queue_free()


class FireOrb extends Area2D:
	var damage: float = 5.0
	var orbit_index: int = 0
	var orbit_count: int = 3
	var orbit_radius: float = 60.0
	var orbit_speed: float = 3.0
	var angle: float = 0.0
	var hit_cooldown: Dictionary = {}

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2
		angle = orbit_index * TAU / orbit_count

		# Visual
		var poly = Polygon2D.new()
		poly.polygon = _circle(10)
		poly.color = Color(1.0, 0.5, 0.1, 0.9)
		add_child(poly)

		var glow = Polygon2D.new()
		glow.polygon = _circle(14)
		glow.color = Color(1.0, 0.6, 0.2, 0.3)
		glow.z_index = -1
		add_child(glow)

		# Collision
		var shape = CircleShape2D.new()
		shape.radius = 12
		var col = CollisionShape2D.new()
		col.shape = shape
		add_child(col)

		area_entered.connect(_on_hit)

	func _circle(radius: float) -> PackedVector2Array:
		var points: PackedVector2Array = []
		for i in 12:
			points.append(Vector2.from_angle(i * TAU / 12) * radius)
		return points

	func _physics_process(delta: float) -> void:
		angle += orbit_speed * delta
		position = Vector2.from_angle(angle) * orbit_radius

		# Update cooldowns
		for enemy in hit_cooldown.keys():
			hit_cooldown[enemy] -= delta
			if hit_cooldown[enemy] <= 0:
				hit_cooldown.erase(enemy)

	func _on_hit(area: Area2D) -> void:
		var enemy = area.get_parent()
		if enemy in hit_cooldown:
			return

		if enemy.has_method("take_damage"):
			enemy.take_damage(damage * Global.damage_mult, Vector2.ZERO)
			hit_cooldown[enemy] = 0.5


class LightningBolt extends Node2D:
	var damage: float = 15.0
	var crit: bool = false
	var start_pos: Vector2
	var end_pos: Vector2

	func _ready() -> void:
		global_position = Vector2.ZERO

		# Draw lightning
		var line = Line2D.new()
		line.width = 4 if not crit else 6
		line.default_color = Color(0.4, 0.7, 1.0) if not crit else Color(1.0, 0.9, 0.4)

		var points: Array[Vector2] = [start_pos]
		var segments = 6
		var current = start_pos
		for i in segments - 1:
			var t = float(i + 1) / segments
			var target = start_pos.lerp(end_pos, t)
			target += Vector2(randf_range(-20, 20), randf_range(-20, 20))
			points.append(target)
			current = target
		points.append(end_pos)

		line.points = PackedVector2Array(points)
		add_child(line)

		# Deal damage
		_deal_damage()

		# Fade out
		var tween = create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)

	func _deal_damage() -> void:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy.global_position.distance_to(end_pos) < 30:
				if enemy.has_method("take_damage"):
					var final_damage = damage * (Global.crit_damage if crit else 1.0)
					enemy.take_damage(final_damage, Vector2.ZERO)
				break


class HolySmite extends Node2D:
	var damage: float = 20.0
	var crit: bool = false
	var radius: float = 100.0

	func _ready() -> void:
		# Visual circle
		var circle = Polygon2D.new()
		var points: PackedVector2Array = []
		for i in 32:
			points.append(Vector2.from_angle(i * TAU / 32) * radius)
		circle.polygon = points
		circle.color = Color(1.0, 0.95, 0.6, 0.6) if not crit else Color(1.0, 0.8, 0.3, 0.7)
		add_child(circle)

		# Inner glow
		var inner = Polygon2D.new()
		var inner_points: PackedVector2Array = []
		for i in 32:
			inner_points.append(Vector2.from_angle(i * TAU / 32) * (radius * 0.5))
		inner.polygon = inner_points
		inner.color = Color(1.0, 1.0, 0.8, 0.8)
		add_child(inner)

		# Deal damage to all enemies in radius
		_deal_damage()

		# Animate
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(self, "modulate:a", 0.0, 0.4)
		tween.tween_callback(queue_free)

	func _deal_damage() -> void:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy.global_position.distance_to(global_position) <= radius:
				if enemy.has_method("take_damage"):
					var final_damage = damage * (Global.crit_damage if crit else 1.0)
					enemy.take_damage(final_damage, Vector2.ZERO)
