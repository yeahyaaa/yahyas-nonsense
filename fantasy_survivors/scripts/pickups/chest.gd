extends Area2D
class_name Chest
## Chest - Dropped by elite monsters, gives 1-3 skill powerups based on luck

signal chest_opened(powerup_count: int)

@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 2.0
@export var glow_pulse_speed: float = 1.5

var initial_y: float
var time_alive: float = 0.0
var is_opening: bool = false

# Available powerups pool
var powerup_pool: Array[Dictionary] = [
	# Damage powerups
	{"id": "damage_up", "name": "Damage +10%", "stat": "damage", "value": 0.1, "is_mult": true, "icon_color": Color(1.0, 0.3, 0.3)},
	{"id": "crit_chance", "name": "Crit Chance +5%", "stat": "crit_chance", "value": 0.05, "is_mult": false, "icon_color": Color(1.0, 0.5, 0.0)},
	{"id": "crit_damage", "name": "Crit Damage +25%", "stat": "crit_damage", "value": 0.25, "is_mult": false, "icon_color": Color(1.0, 0.6, 0.1)},
	{"id": "attack_speed", "name": "Attack Speed +10%", "stat": "attack_speed", "value": 0.1, "is_mult": false, "icon_color": Color(0.9, 0.9, 0.3)},

	# Defense powerups
	{"id": "health_up", "name": "Max Health +15", "stat": "max_health", "value": 15, "is_mult": false, "icon_color": Color(0.3, 0.9, 0.3)},
	{"id": "armor_up", "name": "Armor +5", "stat": "armor", "value": 5, "is_mult": false, "icon_color": Color(0.5, 0.5, 0.7)},
	{"id": "health_regen", "name": "HP Regen +0.5/s", "stat": "health_regen", "value": 0.5, "is_mult": false, "icon_color": Color(0.4, 1.0, 0.4)},

	# Utility powerups
	{"id": "move_speed", "name": "Move Speed +8%", "stat": "move_speed", "value": 0.08, "is_mult": true, "icon_color": Color(0.3, 0.7, 1.0)},
	{"id": "pickup_range", "name": "Pickup Range +20", "stat": "pickup_range", "value": 20, "is_mult": false, "icon_color": Color(0.8, 0.5, 1.0)},
	{"id": "luck_up", "name": "Luck +0.2", "stat": "luck", "value": 0.2, "is_mult": false, "icon_color": Color(1.0, 0.9, 0.3)},
	{"id": "xp_bonus", "name": "XP Gain +10%", "stat": "xp_multiplier", "value": 0.1, "is_mult": false, "icon_color": Color(0.6, 0.3, 0.9)},
]

func _ready() -> void:
	collision_layer = 32
	collision_mask = 1  # Player can interact
	initial_y = position.y

	_create_visual()

	# Connect for player interaction
	area_entered.connect(_on_player_contact)

func _process(delta: float) -> void:
	if is_opening:
		return

	time_alive += delta

	# Bobbing animation
	position.y = initial_y + sin(time_alive * bob_speed) * bob_amplitude

func _create_visual() -> void:
	# Chest base
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-16, 0),
		Vector2(16, 0),
		Vector2(16, 12),
		Vector2(-16, 12)
	])
	base.color = Color(0.5, 0.3, 0.15)
	add_child(base)

	# Chest lid
	var lid = Polygon2D.new()
	lid.name = "Lid"
	lid.polygon = PackedVector2Array([
		Vector2(-16, 0),
		Vector2(16, 0),
		Vector2(14, -10),
		Vector2(-14, -10)
	])
	lid.color = Color(0.6, 0.35, 0.2)
	add_child(lid)

	# Gold trim
	var trim = Polygon2D.new()
	trim.polygon = PackedVector2Array([
		Vector2(-14, -2),
		Vector2(14, -2),
		Vector2(14, 2),
		Vector2(-14, 2)
	])
	trim.color = Color(1.0, 0.85, 0.2)
	add_child(trim)

	# Lock
	var lock = Polygon2D.new()
	lock.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)
	])
	lock.color = Color(0.9, 0.75, 0.1)
	add_child(lock)

	# Glow effect
	var glow = ColorRect.new()
	glow.name = "Glow"
	glow.size = Vector2(48, 32)
	glow.position = Vector2(-24, -16)
	glow.color = Color(1.0, 0.9, 0.4, 0.2)
	glow.z_index = -1
	add_child(glow)

	# Pulse animation for glow
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(glow, "color:a", 0.4, 0.5)
	tween.tween_property(glow, "color:a", 0.15, 0.5)

	# Collision
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 24)
	var collision = CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, 6)
	add_child(collision)

func _on_player_contact(area: Area2D) -> void:
	if is_opening:
		return

	var player = area.get_parent()
	if player.is_in_group("player"):
		open_chest()

func open_chest() -> void:
	is_opening = true
	PlayerStats.chests_opened += 1

	# Calculate powerups based on luck
	var powerup_count = PlayerStats.calculate_chest_powerups()
	chest_opened.emit(powerup_count)

	# Opening animation
	await _play_open_animation()

	# Apply random powerups
	var applied_powerups: Array[Dictionary] = []
	for i in powerup_count:
		var powerup = _get_random_powerup(applied_powerups)
		_apply_powerup(powerup)
		applied_powerups.append(powerup)
		await _spawn_powerup_popup(powerup, i)

	# Final effect and cleanup
	await _play_finish_effect()
	queue_free()

func _play_open_animation() -> Tween:
	var lid = get_node_or_null("Lid")
	if lid:
		var tween = create_tween()
		tween.tween_property(lid, "rotation", deg_to_rad(-120), 0.3)
		tween.parallel().tween_property(lid, "position:y", -15, 0.3)
		await tween.finished
		return tween
	return null

func _get_random_powerup(exclude: Array[Dictionary]) -> Dictionary:
	var available = powerup_pool.filter(func(p): return p not in exclude)
	if available.is_empty():
		available = powerup_pool
	return available[randi() % available.size()]

func _apply_powerup(powerup: Dictionary) -> void:
	PlayerStats.modify_stat(powerup["stat"], powerup["value"], powerup["is_mult"])

func _spawn_powerup_popup(powerup: Dictionary, index: int) -> void:
	# Create floating text showing what was gained
	var popup = Label.new()
	popup.text = powerup["name"]
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", powerup["icon_color"])
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.global_position = global_position + Vector2(-50, -40 - index * 25)

	get_tree().current_scene.add_child(popup)

	# Float up and fade
	var tween = create_tween()
	tween.parallel().tween_property(popup, "position:y", popup.position.y - 30, 1.0)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(popup.queue_free)

	await get_tree().create_timer(0.3).timeout

func _play_finish_effect() -> void:
	# Burst of particles/sparkles
	for i in 8:
		var particle = Polygon2D.new()
		particle.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(0, -3), Vector2(3, 0), Vector2(0, 3)
		])
		particle.color = Color(1.0, 0.9, 0.3, 0.9)
		particle.global_position = global_position

		var angle = i * TAU / 8
		var direction = Vector2.from_angle(angle)

		get_tree().current_scene.add_child(particle)

		var tween = create_tween()
		tween.parallel().tween_property(particle, "position", particle.position + direction * 50, 0.4)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.4)
		tween.tween_callback(particle.queue_free)

	await get_tree().create_timer(0.5).timeout
