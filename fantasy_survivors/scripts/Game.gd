extends Node2D

# === GAME STATE ===
var game_time: float = 0.0
var is_playing: bool = true
var is_paused: bool = false

# === PLAYER STATS ===
var max_hp: float = 100.0
var current_hp: float = 100.0
var move_speed: float = 300.0
var damage: float = 15.0
var xp: int = 0
var level: int = 1
var xp_needed: int = 10
var kills: int = 0
var luck: float = 1.0

# === REFERENCES ===
var player: CharacterBody2D
var camera: Camera2D
var enemies_node: Node2D
var projectiles_node: Node2D
var pickups_node: Node2D
var ui_layer: CanvasLayer

# === UI REFS ===
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var time_label: Label
var kills_label: Label
var levelup_panel: Control
var gameover_panel: Control
var joystick_left: Control
var joystick_right: Control

# === JOYSTICK STATE ===
var left_touch_idx: int = -1
var right_touch_idx: int = -1
var move_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.RIGHT

# === WEAPONS ===
var sword_timer: float = 0.0
var magic_timer: float = 0.0
var weapons: Array = ["sword"]
var weapon_levels: Dictionary = {"sword": 1, "magic": 0, "arrow": 0, "orbit": 0}

# === SPAWNING ===
var spawn_timer: float = 0.0
var enemy_count: int = 0

func _ready():
	_create_world()
	_create_player()
	_create_ui()
	_spawn_initial_enemies()

func _process(delta):
	if not is_playing or is_paused:
		return

	game_time += delta
	_update_timers(delta)
	_update_ui()
	_handle_weapons(delta)
	_handle_spawning(delta)
	_handle_pickups()
	_regen_hp(delta)

func _physics_process(delta):
	if not is_playing or is_paused:
		return
	_handle_input()
	_move_player(delta)
	_move_enemies(delta)

func _input(event):
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

# === WORLD CREATION ===
func _create_world():
	# Ground tiles
	for x in range(-20, 21):
		for y in range(-20, 21):
			var tile = ColorRect.new()
			tile.size = Vector2(100, 100)
			tile.position = Vector2(x * 100, y * 100)
			tile.color = Color(0.12, 0.14, 0.1) if (x + y) % 2 == 0 else Color(0.11, 0.13, 0.09)
			tile.z_index = -10
			add_child(tile)

	# Containers
	enemies_node = Node2D.new()
	enemies_node.name = "Enemies"
	add_child(enemies_node)

	projectiles_node = Node2D.new()
	projectiles_node.name = "Projectiles"
	add_child(projectiles_node)

	pickups_node = Node2D.new()
	pickups_node.name = "Pickups"
	add_child(pickups_node)

# === PLAYER ===
func _create_player():
	player = CharacterBody2D.new()
	player.position = Vector2.ZERO
	add_child(player)

	# Body
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-14,-20), Vector2(14,-20), Vector2(16,18), Vector2(-16,18)])
	body.color = Color(0.3, 0.4, 0.6)
	player.add_child(body)

	# Head
	var head = Polygon2D.new()
	head.polygon = _make_circle(12)
	head.position = Vector2(0, -30)
	head.color = Color(0.9, 0.75, 0.6)
	player.add_child(head)

	# Shadow
	var shadow = Polygon2D.new()
	shadow.polygon = _make_circle(16)
	shadow.position = Vector2(0, 20)
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.z_index = -1
	player.add_child(shadow)

	# Collision
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 18
	col.shape = shape
	player.add_child(col)

	# Camera
	camera = Camera2D.new()
	camera.zoom = Vector2(0.8, 0.8)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)
	camera.make_current()

func _make_circle(radius: float, segments: int = 16) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in segments:
		var angle = i * TAU / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

# === INPUT ===
func _handle_input():
	# Keyboard
	var kb_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): kb_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): kb_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): kb_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): kb_dir.x += 1

	if kb_dir.length() > 0:
		move_vector = kb_dir.normalized()
		aim_vector = move_vector

func _handle_touch(event: InputEventScreenTouch):
	var screen_half = get_viewport().get_visible_rect().size.x / 2

	if event.pressed:
		if event.position.x < screen_half and left_touch_idx == -1:
			left_touch_idx = event.index
			_update_joystick_visual(joystick_left, Vector2.ZERO)
		elif event.position.x >= screen_half and right_touch_idx == -1:
			right_touch_idx = event.index
			_update_joystick_visual(joystick_right, Vector2.ZERO)
	else:
		if event.index == left_touch_idx:
			left_touch_idx = -1
			move_vector = Vector2.ZERO
			_update_joystick_visual(joystick_left, Vector2.ZERO)
		elif event.index == right_touch_idx:
			right_touch_idx = -1
			_update_joystick_visual(joystick_right, Vector2.ZERO)

func _handle_drag(event: InputEventScreenDrag):
	if event.index == left_touch_idx:
		var joy_center = joystick_left.global_position + joystick_left.size / 2
		var diff = event.position - joy_center
		if diff.length() > 60:
			diff = diff.normalized() * 60
		move_vector = diff / 60.0
		_update_joystick_visual(joystick_left, diff)
	elif event.index == right_touch_idx:
		var joy_center = joystick_right.global_position + joystick_right.size / 2
		var diff = event.position - joy_center
		if diff.length() > 60:
			diff = diff.normalized() * 60
		if diff.length() > 10:
			aim_vector = diff.normalized()
		_update_joystick_visual(joystick_right, diff)

func _update_joystick_visual(joystick: Control, offset: Vector2):
	if joystick and joystick.has_node("Knob"):
		joystick.get_node("Knob").position = joystick.size / 2 - Vector2(25, 25) + offset

func _move_player(delta):
	if move_vector.length() > 0.1:
		player.velocity = move_vector * move_speed
	else:
		player.velocity = Vector2.ZERO
	player.move_and_slide()

# === WEAPONS ===
func _handle_weapons(delta):
	# Sword
	if weapon_levels["sword"] > 0:
		sword_timer -= delta
		if sword_timer <= 0:
			_attack_sword()
			sword_timer = 1.0 / (1 + weapon_levels["sword"] * 0.2)

	# Magic
	if weapon_levels["magic"] > 0:
		magic_timer -= delta
		if magic_timer <= 0:
			_attack_magic()
			magic_timer = 1.2 / (1 + weapon_levels["magic"] * 0.15)

func _attack_sword():
	var slash = Area2D.new()
	slash.position = player.position + aim_vector * 40
	slash.rotation = aim_vector.angle()

	var poly = Polygon2D.new()
	var size = 50 + weapon_levels["sword"] * 10
	poly.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(size, -size * 0.6),
		Vector2(size * 1.2, 0),
		Vector2(size, size * 0.6)
	])
	poly.color = Color(0.8, 0.8, 0.95, 0.8)
	slash.add_child(poly)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = size
	col.shape = shape
	col.position = Vector2(size * 0.6, 0)
	slash.add_child(col)

	slash.collision_layer = 0
	slash.collision_mask = 2
	slash.set_meta("damage", damage * (1 + weapon_levels["sword"] * 0.3))
	slash.set_meta("hit_enemies", [])
	slash.area_entered.connect(_on_projectile_hit.bind(slash))

	projectiles_node.add_child(slash)

	# Fade out
	var tween = create_tween()
	tween.tween_property(poly, "modulate:a", 0.0, 0.2)
	tween.tween_callback(slash.queue_free)

func _attack_magic():
	var nearest = _find_nearest_enemy()
	if not nearest:
		return

	var missile = Area2D.new()
	missile.position = player.position

	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-10,-5), Vector2(10,0), Vector2(-10,5), Vector2(-5,0)])
	poly.color = Color(0.4, 0.5, 0.95)
	missile.add_child(poly)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	col.shape = shape
	missile.add_child(col)

	missile.collision_layer = 0
	missile.collision_mask = 2
	missile.set_meta("damage", damage * (0.8 + weapon_levels["magic"] * 0.25))
	missile.set_meta("target", nearest)
	missile.set_meta("speed", 350)
	missile.area_entered.connect(_on_magic_hit.bind(missile))

	projectiles_node.add_child(missile)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist = 99999.0
	for enemy in enemies_node.get_children():
		var dist = player.position.distance_to(enemy.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _on_projectile_hit(area: Area2D, projectile: Area2D):
	var hit_list = projectile.get_meta("hit_enemies")
	if area in hit_list:
		return
	hit_list.append(area)
	projectile.set_meta("hit_enemies", hit_list)
	_damage_enemy(area.get_parent(), projectile.get_meta("damage"))

func _on_magic_hit(area: Area2D, missile: Area2D):
	_damage_enemy(area.get_parent(), missile.get_meta("damage"))
	missile.queue_free()

# === ENEMIES ===
func _spawn_enemy(enemy_type: String, pos: Vector2):
	var enemy = CharacterBody2D.new()
	enemy.position = pos

	var data = _get_enemy_data(enemy_type)
	enemy.set_meta("type", enemy_type)
	enemy.set_meta("hp", data.hp * (1 + game_time / 120))
	enemy.set_meta("max_hp", data.hp * (1 + game_time / 120))
	enemy.set_meta("speed", data.speed)
	enemy.set_meta("damage", data.damage * (1 + game_time / 180))
	enemy.set_meta("xp", data.xp)
	enemy.set_meta("is_elite", false)

	# Body
	var body = Polygon2D.new()
	body.polygon = _make_circle(data.size)
	body.color = data.color
	enemy.add_child(body)

	# Hitbox
	var hitbox = Area2D.new()
	hitbox.collision_layer = 2
	hitbox.collision_mask = 0
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = data.size
	col.shape = shape
	hitbox.add_child(col)
	enemy.add_child(hitbox)

	# Body collision
	var body_col = CollisionShape2D.new()
	var body_shape = CircleShape2D.new()
	body_shape.radius = data.size * 0.8
	body_col.shape = body_shape
	enemy.add_child(body_col)

	enemies_node.add_child(enemy)
	enemy_count += 1

func _get_enemy_data(enemy_type: String) -> Dictionary:
	match enemy_type:
		"skeleton": return {"hp": 15, "speed": 100, "damage": 8, "xp": 1, "size": 14, "color": Color(0.9, 0.9, 0.85)}
		"zombie": return {"hp": 30, "speed": 50, "damage": 12, "xp": 2, "size": 18, "color": Color(0.4, 0.5, 0.35)}
		"goblin": return {"hp": 10, "speed": 130, "damage": 6, "xp": 1, "size": 10, "color": Color(0.3, 0.55, 0.3)}
		"orc": return {"hp": 50, "speed": 60, "damage": 18, "xp": 3, "size": 22, "color": Color(0.35, 0.45, 0.3)}
		"imp": return {"hp": 12, "speed": 90, "damage": 10, "xp": 2, "size": 12, "color": Color(0.7, 0.25, 0.25)}
		_: return {"hp": 15, "speed": 80, "damage": 8, "xp": 1, "size": 14, "color": Color(0.8, 0.8, 0.8)}

func _move_enemies(delta):
	for enemy in enemies_node.get_children():
		var dir = (player.position - enemy.position).normalized()
		enemy.velocity = dir * enemy.get_meta("speed")
		enemy.move_and_slide()

		# Attack player
		if enemy.position.distance_to(player.position) < 30:
			_take_damage(enemy.get_meta("damage") * delta)

func _damage_enemy(enemy: Node2D, amount: float):
	if not is_instance_valid(enemy):
		return
	var hp = enemy.get_meta("hp") - amount
	enemy.set_meta("hp", hp)

	# Flash
	if enemy.get_child_count() > 0:
		enemy.get_child(0).modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(enemy) and enemy.get_child_count() > 0:
			enemy.get_child(0).modulate = Color.WHITE

	if hp <= 0:
		_kill_enemy(enemy)

func _kill_enemy(enemy: Node2D):
	kills += 1
	var xp_val = enemy.get_meta("xp")
	var pos = enemy.position

	# Spawn XP
	_spawn_xp(pos, xp_val)

	# Chance for gold
	if randf() < 0.3:
		_spawn_gold(pos)

	# Elite chest
	if enemy.get_meta("is_elite") and randf() < 0.4:
		_spawn_chest(pos)

	enemy_count -= 1
	enemy.queue_free()

func _spawn_initial_enemies():
	for i in 5:
		var angle = randf() * TAU
		var dist = randf_range(300, 500)
		_spawn_enemy("skeleton", Vector2(cos(angle), sin(angle)) * dist)

func _handle_spawning(delta):
	spawn_timer -= delta
	if spawn_timer <= 0 and enemy_count < 100:
		var count = 2 + int(game_time / 20)
		for i in count:
			var angle = randf() * TAU
			var dist = randf_range(400, 600)
			var pos = player.position + Vector2(cos(angle), sin(angle)) * dist

			var types = ["skeleton", "skeleton", "zombie", "goblin"]
			if game_time > 60: types.append("orc")
			if game_time > 90: types.append("imp")

			_spawn_enemy(types[randi() % types.size()], pos)

		# Elite every 30 seconds
		if int(game_time) % 30 < 2 and game_time > 25:
			var angle = randf() * TAU
			var pos = player.position + Vector2(cos(angle), sin(angle)) * 500
			var elite = _spawn_elite(pos)

		spawn_timer = max(0.3, 1.5 - game_time / 180)

func _spawn_elite(pos: Vector2):
	var enemy = CharacterBody2D.new()
	enemy.position = pos

	var base_hp = 80 * (1 + game_time / 60)
	enemy.set_meta("type", "elite")
	enemy.set_meta("hp", base_hp)
	enemy.set_meta("max_hp", base_hp)
	enemy.set_meta("speed", 70)
	enemy.set_meta("damage", 20)
	enemy.set_meta("xp", 15)
	enemy.set_meta("is_elite", true)

	var body = Polygon2D.new()
	body.polygon = _make_circle(28)
	body.color = Color(1.0, 0.85, 0.3)
	enemy.add_child(body)

	var hitbox = Area2D.new()
	hitbox.collision_layer = 2
	hitbox.collision_mask = 0
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 28
	col.shape = shape
	hitbox.add_child(col)
	enemy.add_child(hitbox)

	var body_col = CollisionShape2D.new()
	var body_shape = CircleShape2D.new()
	body_shape.radius = 24
	body_col.shape = body_shape
	enemy.add_child(body_col)

	enemies_node.add_child(enemy)
	enemy_count += 1

# === PICKUPS ===
func _spawn_xp(pos: Vector2, value: int):
	var xp_gem = Area2D.new()
	xp_gem.position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	xp_gem.set_meta("value", value)
	xp_gem.collision_layer = 4
	xp_gem.collision_mask = 0

	var poly = Polygon2D.new()
	var size = 6 + min(value, 10)
	poly.polygon = PackedVector2Array([Vector2(0,-size), Vector2(size*0.6,0), Vector2(0,size*0.4), Vector2(-size*0.6,0)])
	poly.color = Color(0.3, 0.85, 0.4) if value < 5 else Color(0.4, 0.5, 0.95)
	xp_gem.add_child(poly)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = size
	col.shape = shape
	xp_gem.add_child(col)

	pickups_node.add_child(xp_gem)

func _spawn_gold(pos: Vector2):
	var gold = Area2D.new()
	gold.position = pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	gold.set_meta("type", "gold")
	gold.collision_layer = 4
	gold.collision_mask = 0

	var poly = Polygon2D.new()
	poly.polygon = _make_circle(7)
	poly.color = Color(1.0, 0.85, 0.2)
	gold.add_child(poly)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8
	col.shape = shape
	gold.add_child(col)

	pickups_node.add_child(gold)

func _spawn_chest(pos: Vector2):
	var chest = Area2D.new()
	chest.position = pos
	chest.set_meta("type", "chest")
	chest.collision_layer = 4
	chest.collision_mask = 0

	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-20,0), Vector2(20,0), Vector2(20,16), Vector2(-20,16)])
	body.color = Color(0.5, 0.3, 0.15)
	chest.add_child(body)

	var lid = Polygon2D.new()
	lid.polygon = PackedVector2Array([Vector2(-20,0), Vector2(20,0), Vector2(18,-12), Vector2(-18,-12)])
	lid.color = Color(0.6, 0.35, 0.2)
	chest.add_child(lid)

	var trim = Polygon2D.new()
	trim.polygon = PackedVector2Array([Vector2(-18,-2), Vector2(18,-2), Vector2(18,2), Vector2(-18,2)])
	trim.color = Color(1.0, 0.85, 0.2)
	chest.add_child(trim)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 28)
	col.shape = shape
	col.position = Vector2(0, 8)
	chest.add_child(col)

	pickups_node.add_child(chest)

func _handle_pickups():
	var pickup_range = 80
	for pickup in pickups_node.get_children():
		var dist = player.position.distance_to(pickup.position)

		# Magnetize
		if dist < pickup_range:
			var dir = (player.position - pickup.position).normalized()
			pickup.position += dir * 400 * get_process_delta_time()

		# Collect
		if dist < 25:
			if pickup.has_meta("value"):  # XP
				_add_xp(pickup.get_meta("value"))
			elif pickup.get_meta("type") == "gold":
				pass  # Could add gold counter
			elif pickup.get_meta("type") == "chest":
				_open_chest()
			pickup.queue_free()

func _open_chest():
	# Give 1-3 random powerups based on luck
	var count = 1
	if randf() < 0.1 * luck: count = 2
	if randf() < 0.02 * luck: count = 3

	for i in count:
		var bonuses = [
			func(): damage += 3,
			func(): max_hp += 15; current_hp += 15,
			func(): move_speed += 15,
			func(): luck += 0.2,
		]
		bonuses[randi() % bonuses.size()].call()

# === PLAYER DAMAGE/XP ===
func _take_damage(amount: float):
	current_hp -= amount
	current_hp = max(0, current_hp)

	if current_hp <= 0:
		_game_over()

func _regen_hp(delta):
	if current_hp < max_hp:
		current_hp = min(max_hp, current_hp + 0.2 * delta)

func _add_xp(amount: int):
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = int(10 * pow(level, 1.3))
		_level_up()

func _level_up():
	is_paused = true
	get_tree().paused = true
	_show_levelup_ui()

func _show_levelup_ui():
	levelup_panel.visible = true

	# Generate 3 random upgrades
	var upgrades = [
		{"name": "Damage +15%", "action": func(): damage *= 1.15},
		{"name": "Max HP +20", "action": func(): max_hp += 20; current_hp += 20},
		{"name": "Speed +10%", "action": func(): move_speed *= 1.1},
		{"name": "Luck +0.3", "action": func(): luck += 0.3},
		{"name": "Sword Level Up", "action": func(): weapon_levels["sword"] += 1},
	]

	if weapon_levels["magic"] == 0:
		upgrades.append({"name": "NEW: Magic Missile", "action": func(): weapon_levels["magic"] = 1})
	else:
		upgrades.append({"name": "Magic Level Up", "action": func(): weapon_levels["magic"] += 1})

	upgrades.shuffle()
	var chosen = upgrades.slice(0, 3)

	for i in 3:
		var btn = levelup_panel.get_node("Btn" + str(i))
		btn.text = chosen[i]["name"]

		# Disconnect old
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)

		btn.pressed.connect(_on_upgrade_chosen.bind(chosen[i]["action"]))

func _on_upgrade_chosen(action: Callable):
	action.call()
	levelup_panel.visible = false
	is_paused = false
	get_tree().paused = false

func _game_over():
	is_playing = false
	gameover_panel.visible = true
	gameover_panel.get_node("Stats").text = "Time: %s\nLevel: %d\nKills: %d" % [_format_time(), level, kills]

func _format_time() -> String:
	var mins = int(game_time) / 60
	var secs = int(game_time) % 60
	return "%02d:%02d" % [mins, secs]

func _update_timers(delta):
	# Update magic missiles
	for proj in projectiles_node.get_children():
		if proj.has_meta("target"):
			var target = proj.get_meta("target")
			if is_instance_valid(target):
				var dir = (target.position - proj.position).normalized()
				proj.position += dir * proj.get_meta("speed") * delta
				proj.rotation = dir.angle()
			else:
				proj.queue_free()

# === UI ===
func _create_ui():
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	# Top bar bg
	var top_bg = ColorRect.new()
	top_bg.size = Vector2(1080, 100)
	top_bg.color = Color(0, 0, 0, 0.6)
	ui_layer.add_child(top_bg)

	# HP Bar
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(20, 15)
	hp_bar.size = Vector2(250, 25)
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	ui_layer.add_child(hp_bar)

	var hp_label = Label.new()
	hp_label.position = Vector2(20, 42)
	hp_label.text = "HP"
	ui_layer.add_child(hp_label)

	# XP Bar
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(20, 65)
	xp_bar.size = Vector2(200, 18)
	xp_bar.max_value = 10
	xp_bar.value = 0
	xp_bar.show_percentage = false
	ui_layer.add_child(xp_bar)

	level_label = Label.new()
	level_label.position = Vector2(230, 60)
	level_label.text = "Lv.1"
	ui_layer.add_child(level_label)

	# Timer
	time_label = Label.new()
	time_label.position = Vector2(480, 30)
	time_label.text = "00:00"
	ui_layer.add_child(time_label)

	# Kills
	kills_label = Label.new()
	kills_label.position = Vector2(700, 30)
	kills_label.text = "Kills: 0"
	ui_layer.add_child(kills_label)

	# Joysticks
	joystick_left = _create_joystick(Vector2(50, 1650))
	joystick_right = _create_joystick(Vector2(830, 1650))

	# Level Up Panel
	_create_levelup_panel()

	# Game Over Panel
	_create_gameover_panel()

func _create_joystick(pos: Vector2) -> Control:
	var joy = Control.new()
	joy.position = pos
	joy.size = Vector2(200, 200)

	var base = ColorRect.new()
	base.size = Vector2(150, 150)
	base.position = Vector2(25, 25)
	base.color = Color(0.2, 0.2, 0.25, 0.5)
	joy.add_child(base)

	var knob = ColorRect.new()
	knob.name = "Knob"
	knob.size = Vector2(50, 50)
	knob.position = Vector2(75, 75)
	knob.color = Color(0.4, 0.4, 0.5, 0.7)
	joy.add_child(knob)

	ui_layer.add_child(joy)
	return joy

func _create_levelup_panel():
	levelup_panel = Control.new()
	levelup_panel.visible = false
	ui_layer.add_child(levelup_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0, 0, 0, 0.85)
	levelup_panel.add_child(bg)

	var title = Label.new()
	title.position = Vector2(420, 300)
	title.text = "LEVEL UP!"
	levelup_panel.add_child(title)

	for i in 3:
		var btn = Button.new()
		btn.name = "Btn" + str(i)
		btn.position = Vector2(240, 450 + i * 150)
		btn.size = Vector2(600, 120)
		btn.text = "Upgrade " + str(i)
		levelup_panel.add_child(btn)

func _create_gameover_panel():
	gameover_panel = Control.new()
	gameover_panel.visible = false
	ui_layer.add_child(gameover_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0, 0, 0, 0.9)
	gameover_panel.add_child(bg)

	var title = Label.new()
	title.position = Vector2(380, 400)
	title.text = "GAME OVER"
	gameover_panel.add_child(title)

	var stats = Label.new()
	stats.name = "Stats"
	stats.position = Vector2(400, 500)
	stats.text = ""
	gameover_panel.add_child(stats)

	var retry_btn = Button.new()
	retry_btn.position = Vector2(340, 700)
	retry_btn.size = Vector2(400, 80)
	retry_btn.text = "RETRY"
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	gameover_panel.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.position = Vector2(340, 820)
	menu_btn.size = Vector2(400, 80)
	menu_btn.text = "MENU"
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Menu.tscn"))
	gameover_panel.add_child(menu_btn)

func _update_ui():
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	xp_bar.max_value = xp_needed
	xp_bar.value = xp
	level_label.text = "Lv." + str(level)
	time_label.text = _format_time()
	kills_label.text = "Kills: " + str(kills)
