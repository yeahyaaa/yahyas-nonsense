extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

# Stats
var enemy_type: String = "skeleton"
var max_health: float = 20.0
var current_health: float = 20.0
var move_speed: float = 80.0
var damage: float = 10.0
var xp_value: int = 1
var gold_value: int = 1

# Elite
var is_elite: bool = false
const ELITE_HEALTH_MULT: float = 5.0
const ELITE_DAMAGE_MULT: float = 1.5
const ELITE_SIZE_MULT: float = 1.5
const ELITE_XP_MULT: float = 10.0
const ELITE_GOLD_MULT: float = 5.0
const ELITE_CHEST_CHANCE: float = 0.3

# State
var player: Node2D
var knockback: Vector2 = Vector2.ZERO

# Nodes
var sprite: Polygon2D
var hitbox: Area2D

func _ready() -> void:
	add_to_group("enemies")
	_create_visuals()
	_setup_hitbox()

	if is_elite:
		_apply_elite()

	current_health = max_health

func _create_visuals() -> void:
	sprite = Polygon2D.new()
	add_child(sprite)

	match enemy_type:
		"skeleton":
			sprite.polygon = PackedVector2Array([
				Vector2(-10, -18), Vector2(10, -18),
				Vector2(12, 15), Vector2(-12, 15)
			])
			sprite.color = Color(0.9, 0.9, 0.85)
			# Skull
			var skull = Polygon2D.new()
			skull.polygon = _circle(8)
			skull.position = Vector2(0, -22)
			skull.color = Color(0.95, 0.95, 0.9)
			sprite.add_child(skull)
			# Eyes
			for x in [-3, 3]:
				var eye = Polygon2D.new()
				eye.polygon = _circle(2)
				eye.position = Vector2(x, -24)
				eye.color = Color(0.1, 0.1, 0.1)
				sprite.add_child(eye)

		"zombie":
			sprite.polygon = PackedVector2Array([
				Vector2(-14, -20), Vector2(14, -20),
				Vector2(16, 18), Vector2(-16, 18)
			])
			sprite.color = Color(0.4, 0.5, 0.35)
			# Head
			var head = Polygon2D.new()
			head.polygon = _circle(10)
			head.position = Vector2(0, -28)
			head.color = Color(0.5, 0.55, 0.4)
			sprite.add_child(head)

		"goblin":
			sprite.polygon = PackedVector2Array([
				Vector2(-8, -12), Vector2(8, -12),
				Vector2(10, 10), Vector2(-10, 10)
			])
			sprite.color = Color(0.3, 0.5, 0.25)
			# Head
			var head = Polygon2D.new()
			head.polygon = _circle(7)
			head.position = Vector2(0, -18)
			head.color = Color(0.35, 0.55, 0.3)
			sprite.add_child(head)
			# Ears
			for x in [-8, 8]:
				var ear = Polygon2D.new()
				ear.polygon = PackedVector2Array([
					Vector2(0, 0), Vector2(x/2, -8), Vector2(x, -4)
				])
				ear.position = Vector2(0, -18)
				ear.color = Color(0.35, 0.55, 0.3)
				sprite.add_child(ear)

		"orc":
			sprite.polygon = PackedVector2Array([
				Vector2(-16, -24), Vector2(16, -24),
				Vector2(18, 20), Vector2(-18, 20)
			])
			sprite.color = Color(0.35, 0.45, 0.3)
			# Head
			var head = Polygon2D.new()
			head.polygon = _circle(12)
			head.position = Vector2(0, -32)
			head.color = Color(0.4, 0.5, 0.35)
			sprite.add_child(head)

		"imp":
			sprite.polygon = PackedVector2Array([
				Vector2(-8, -14), Vector2(8, -14),
				Vector2(10, 12), Vector2(-10, 12)
			])
			sprite.color = Color(0.6, 0.2, 0.2)
			# Head
			var head = Polygon2D.new()
			head.polygon = _circle(6)
			head.position = Vector2(0, -18)
			head.color = Color(0.7, 0.25, 0.25)
			sprite.add_child(head)
			# Horns
			for x in [-5, 5]:
				var horn = Polygon2D.new()
				horn.polygon = PackedVector2Array([
					Vector2(0, 0), Vector2(x/2, -10), Vector2(x, -6)
				])
				horn.position = Vector2(0, -18)
				horn.color = Color(0.3, 0.15, 0.15)
				sprite.add_child(horn)

		"demon":
			sprite.polygon = PackedVector2Array([
				Vector2(-18, -28), Vector2(18, -28),
				Vector2(20, 22), Vector2(-20, 22)
			])
			sprite.color = Color(0.5, 0.15, 0.15)
			# Head
			var head = Polygon2D.new()
			head.polygon = _circle(14)
			head.position = Vector2(0, -38)
			head.color = Color(0.55, 0.2, 0.2)
			sprite.add_child(head)
			# Big horns
			for x in [-10, 10]:
				var horn = Polygon2D.new()
				horn.polygon = PackedVector2Array([
					Vector2(0, 0), Vector2(x, -20), Vector2(x*1.5, -10)
				])
				horn.position = Vector2(0, -38)
				horn.color = Color(0.2, 0.1, 0.1)
				sprite.add_child(horn)

	# Shadow
	var shadow = Polygon2D.new()
	shadow.polygon = _circle(12)
	shadow.color = Color(0, 0, 0, 0.25)
	shadow.position = Vector2(0, 18)
	shadow.z_index = -1
	add_child(shadow)

func _circle(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i in 12:
		points.append(Vector2.from_angle(i * TAU / 12) * radius)
	return points

func _setup_hitbox() -> void:
	hitbox = Area2D.new()
	hitbox.collision_layer = 2
	hitbox.collision_mask = 4
	add_child(hitbox)

	var shape = CircleShape2D.new()
	shape.radius = 15
	var col = CollisionShape2D.new()
	col.shape = shape
	hitbox.add_child(col)

	# Body collision
	var body_shape = CircleShape2D.new()
	body_shape.radius = 12
	var body_col = CollisionShape2D.new()
	body_col.shape = body_shape
	add_child(body_col)

func _apply_elite() -> void:
	max_health *= ELITE_HEALTH_MULT
	damage *= ELITE_DAMAGE_MULT
	xp_value = int(xp_value * ELITE_XP_MULT)
	gold_value = int(gold_value * ELITE_GOLD_MULT)
	scale *= ELITE_SIZE_MULT
	sprite.modulate = Color(1.3, 1.0, 0.4)  # Golden glow

func _physics_process(delta: float) -> void:
	if Global.state != Global.State.PLAYING:
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	_move(delta)
	_check_attack()

func _move(delta: float) -> void:
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed + knockback
	knockback = knockback.lerp(Vector2.ZERO, 8 * delta)
	move_and_slide()

	# Face direction
	if dir.x != 0:
		sprite.scale.x = 1 if dir.x > 0 else -1

func _check_attack() -> void:
	if global_position.distance_to(player.global_position) < 35:
		if player.has_method("take_damage"):
			player.take_damage(damage)

func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	current_health -= amount
	knockback += knockback_dir * 150

	# Flash white
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(self):
		sprite.modulate = Color(1.3, 1.0, 0.4) if is_elite else Color.WHITE

	if current_health <= 0:
		_die()

func _die() -> void:
	Global.add_kill(enemy_type, is_elite)
	_spawn_drops()
	died.emit(self)
	queue_free()

func _spawn_drops() -> void:
	# XP Gem
	var xp = XPGem.new()
	xp.value = xp_value
	xp.global_position = global_position
	get_parent().add_child(xp)

	# Gold (30% chance, or always for elites)
	if is_elite or randf() < 0.3:
		var gold = GoldPickup.new()
		gold.value = gold_value
		gold.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().add_child(gold)

	# Chest (elites only)
	if is_elite and randf() < ELITE_CHEST_CHANCE:
		var chest = Chest.new()
		chest.global_position = global_position
		get_parent().add_child(chest)

func scale_to_time(time: float) -> void:
	var mult = 1.0 + time / 60.0 * 0.3  # +30% per minute
	max_health *= mult
	current_health = max_health
	damage *= mult
	xp_value = int(xp_value * mult)


# ============ PICKUP CLASSES ============

class PickupBase extends Area2D:
	var magnetized: bool = false
	var target: Node2D
	var bob_offset: float = 0.0

	func _ready() -> void:
		add_to_group("pickups")
		collision_layer = 16
		collision_mask = 0
		bob_offset = randf() * TAU

	func _physics_process(delta: float) -> void:
		if magnetized and is_instance_valid(target):
			var dir = (target.global_position - global_position).normalized()
			position += dir * 400 * delta
			if global_position.distance_to(target.global_position) < 20:
				collect()
		else:
			position.y += sin(Time.get_ticks_msec() / 300.0 + bob_offset) * 0.3

	func magnetize(player: Node2D) -> void:
		magnetized = true
		target = player

	func collect() -> void:
		pass


class XPGem extends PickupBase:
	var value: int = 1

	func _ready() -> void:
		super._ready()

		var poly = Polygon2D.new()
		var size = 5.0 + min(value, 10)
		poly.polygon = PackedVector2Array([
			Vector2(0, -size), Vector2(size*0.6, 0),
			Vector2(0, size*0.5), Vector2(-size*0.6, 0)
		])

		# Color based on value
		if value >= 25:
			poly.color = Color(0.8, 0.4, 0.9)
		elif value >= 10:
			poly.color = Color(0.3, 0.5, 0.9)
		else:
			poly.color = Color(0.3, 0.85, 0.4)
		add_child(poly)

		# Glow
		var glow = poly.duplicate()
		glow.scale = Vector2(1.4, 1.4)
		glow.modulate.a = 0.3
		glow.z_index = -1
		add_child(glow)

		var shape = CircleShape2D.new()
		shape.radius = size
		var col = CollisionShape2D.new()
		col.shape = shape
		add_child(col)

	func collect() -> void:
		Global.add_xp(value)
		queue_free()


class GoldPickup extends PickupBase:
	var value: int = 1

	func _ready() -> void:
		super._ready()

		var poly = Polygon2D.new()
		var radius = 6.0 + min(value, 6)
		var points: PackedVector2Array = []
		for i in 10:
			points.append(Vector2.from_angle(i * TAU / 10) * radius)
		poly.polygon = points
		poly.color = Color(1.0, 0.85, 0.2)
		add_child(poly)

		var inner = Polygon2D.new()
		var inner_points: PackedVector2Array = []
		for i in 10:
			inner_points.append(Vector2.from_angle(i * TAU / 10) * (radius * 0.6))
		inner.polygon = inner_points
		inner.color = Color(0.9, 0.7, 0.15)
		add_child(inner)

		var shape = CircleShape2D.new()
		shape.radius = radius
		var col = CollisionShape2D.new()
		col.shape = shape
		add_child(col)

	func collect() -> void:
		Global.add_gold(value)
		queue_free()


class Chest extends Area2D:
	var opened: bool = false

	func _ready() -> void:
		collision_layer = 16
		collision_mask = 1

		# Base
		var base = Polygon2D.new()
		base.polygon = PackedVector2Array([
			Vector2(-18, 0), Vector2(18, 0),
			Vector2(18, 14), Vector2(-18, 14)
		])
		base.color = Color(0.5, 0.3, 0.15)
		add_child(base)

		# Lid
		var lid = Polygon2D.new()
		lid.name = "Lid"
		lid.polygon = PackedVector2Array([
			Vector2(-18, 0), Vector2(18, 0),
			Vector2(16, -12), Vector2(-16, -12)
		])
		lid.color = Color(0.6, 0.35, 0.2)
		add_child(lid)

		# Trim
		var trim = Polygon2D.new()
		trim.polygon = PackedVector2Array([
			Vector2(-16, -2), Vector2(16, -2),
			Vector2(16, 2), Vector2(-16, 2)
		])
		trim.color = Color(1.0, 0.85, 0.2)
		add_child(trim)

		var shape = RectangleShape2D.new()
		shape.size = Vector2(36, 26)
		var col = CollisionShape2D.new()
		col.shape = shape
		col.position = Vector2(0, 7)
		add_child(col)

		area_entered.connect(_on_player_enter)

	func _on_player_enter(area: Area2D) -> void:
		if opened:
			return
		var parent = area.get_parent()
		if parent.is_in_group("player"):
			_open()

	func _open() -> void:
		opened = true
		Global.chests_opened += 1

		# Animate lid
		var lid = get_node("Lid")
		var tween = create_tween()
		tween.tween_property(lid, "rotation", -2.0, 0.3)
		tween.tween_property(lid, "position:y", -15, 0.3)

		# Spawn powerups
		var count = Global.calculate_chest_powerups()
		for i in count:
			await get_tree().create_timer(0.2).timeout
			var powerup = Global.get_random_powerup()
			Global.apply_powerup(powerup)
			_show_powerup_text(powerup["name"], i)

		await get_tree().create_timer(1.0).timeout
		queue_free()

	func _show_powerup_text(text: String, index: int) -> void:
		var label = Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		label.position = Vector2(-50, -40 - index * 25)
		add_child(label)

		var tween = create_tween()
		tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
		tween.tween_callback(label.queue_free)
