extends Node2D

# GAME STATE
var playing := false
var game_time := 0.0
var hp := 100.0
var max_hp := 100.0
var xp := 0
var level := 1
var xp_need := 10
var kills := 0
var damage := 15.0
var speed := 250.0
var luck := 1.0
var sword_cd := 0.0
var magic_cd := 0.0
var magic_level := 0
var paused := false

# NODES
var player: Node2D
var cam: Camera2D
var enemies: Node2D
var bullets: Node2D
var drops: Node2D

# UI
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var lv_lbl: Label
var time_lbl: Label
var kill_lbl: Label
var menu_ui: Control
var game_ui: Control
var lvlup_ui: Control
var over_ui: Control
var over_lbl: Label

# INPUT
var move_dir := Vector2.ZERO

func _ready():
	_build_menu()

func _process(d):
	if not playing or paused:
		return
	game_time += d
	_do_input()
	_do_move(d)
	_do_weapon(d)
	_do_enemies(d)
	_do_drops()
	_do_spawn(d)
	_do_regen(d)
	_do_ui()

func _input(e):
	if e is InputEventScreenTouch and e.pressed:
		if not playing:
			return
		var half = get_viewport().get_visible_rect().size.x / 2
		if e.position.x < half:
			move_dir = (e.position - Vector2(100, get_viewport().get_visible_rect().size.y - 100)).normalized()

func _do_input():
	var dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
	if dir.length() > 0:
		move_dir = dir.normalized()

func _do_move(d):
	player.position += move_dir * speed * d
	cam.position = player.position

func _do_regen(d):
	if hp < max_hp:
		hp = min(max_hp, hp + 0.3 * d)

# === BUILD MENU ===
func _build_menu():
	menu_ui = Control.new()
	add_child(menu_ui)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_ui.add_child(bg)

	var title = Label.new()
	title.text = "FANTASY SURVIVORS"
	title.position = Vector2(250, 150)
	menu_ui.add_child(title)

	var btn = Button.new()
	btn.text = "PLAY"
	btn.position = Vector2(350, 300)
	btn.size = Vector2(100, 50)
	btn.pressed.connect(_start_game)
	menu_ui.add_child(btn)

	var info = Label.new()
	info.text = "WASD = Move\nAuto-attack enemies\nCollect XP, level up!"
	info.position = Vector2(300, 400)
	menu_ui.add_child(info)

func _start_game():
	menu_ui.queue_free()
	_build_game()
	playing = true

# === BUILD GAME ===
func _build_game():
	# Ground
	for x in range(-15, 16):
		for y in range(-15, 16):
			var t = ColorRect.new()
			t.size = Vector2(64, 64)
			t.position = Vector2(x * 64, y * 64)
			t.color = Color(0.12, 0.14, 0.1) if (x+y) % 2 == 0 else Color(0.1, 0.12, 0.08)
			t.z_index = -10
			add_child(t)

	# Containers
	enemies = Node2D.new()
	add_child(enemies)
	bullets = Node2D.new()
	add_child(bullets)
	drops = Node2D.new()
	add_child(drops)

	# Player
	player = Node2D.new()
	player.position = Vector2.ZERO
	add_child(player)

	var body = _rect(Vector2(-12, -18), Vector2(24, 36), Color(0.3, 0.4, 0.6))
	player.add_child(body)
	var head = _circle(10, Color(0.9, 0.75, 0.6))
	head.position.y = -28
	player.add_child(head)
	var shadow = _circle(14, Color(0, 0, 0, 0.3))
	shadow.position.y = 20
	shadow.z_index = -1
	player.add_child(shadow)

	# Camera
	cam = Camera2D.new()
	cam.make_current()
	add_child(cam)

	# UI
	_build_ui()

	# Spawn initial enemies
	for i in 5:
		_spawn_enemy()

func _build_ui():
	game_ui = CanvasLayer.new()
	add_child(game_ui)

	var top = ColorRect.new()
	top.size = Vector2(800, 50)
	top.color = Color(0, 0, 0, 0.6)
	game_ui.add_child(top)

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(10, 10)
	hp_bar.size = Vector2(150, 20)
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	game_ui.add_child(hp_bar)

	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(10, 32)
	xp_bar.size = Vector2(100, 12)
	xp_bar.max_value = 10
	xp_bar.value = 0
	xp_bar.show_percentage = false
	game_ui.add_child(xp_bar)

	lv_lbl = Label.new()
	lv_lbl.position = Vector2(115, 28)
	lv_lbl.text = "Lv.1"
	game_ui.add_child(lv_lbl)

	time_lbl = Label.new()
	time_lbl.position = Vector2(350, 15)
	time_lbl.text = "00:00"
	game_ui.add_child(time_lbl)

	kill_lbl = Label.new()
	kill_lbl.position = Vector2(550, 15)
	kill_lbl.text = "Kills: 0"
	game_ui.add_child(kill_lbl)

	# Level up UI (hidden)
	lvlup_ui = Control.new()
	lvlup_ui.visible = false
	game_ui.add_child(lvlup_ui)

	var lbg = ColorRect.new()
	lbg.size = Vector2(800, 600)
	lbg.color = Color(0, 0, 0, 0.85)
	lvlup_ui.add_child(lbg)

	var ltitle = Label.new()
	ltitle.text = "LEVEL UP! Choose:"
	ltitle.position = Vector2(320, 100)
	lvlup_ui.add_child(ltitle)

	for i in 3:
		var b = Button.new()
		b.name = "U" + str(i)
		b.position = Vector2(250, 180 + i * 100)
		b.size = Vector2(300, 70)
		lvlup_ui.add_child(b)

	# Game over UI (hidden)
	over_ui = Control.new()
	over_ui.visible = false
	game_ui.add_child(over_ui)

	var obg = ColorRect.new()
	obg.size = Vector2(800, 600)
	obg.color = Color(0, 0, 0, 0.9)
	over_ui.add_child(obg)

	over_lbl = Label.new()
	over_lbl.position = Vector2(320, 150)
	over_lbl.text = "GAME OVER"
	over_ui.add_child(over_lbl)

	var rbtn = Button.new()
	rbtn.text = "RETRY"
	rbtn.position = Vector2(350, 350)
	rbtn.size = Vector2(100, 50)
	rbtn.pressed.connect(func(): get_tree().reload_current_scene())
	over_ui.add_child(rbtn)

func _do_ui():
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	xp_bar.max_value = xp_need
	xp_bar.value = xp
	lv_lbl.text = "Lv." + str(level)
	var m = int(game_time) / 60
	var s = int(game_time) % 60
	time_lbl.text = "%02d:%02d" % [m, s]
	kill_lbl.text = "Kills: " + str(kills)

# === HELPERS ===
func _rect(pos: Vector2, size: Vector2, col: Color) -> ColorRect:
	var r = ColorRect.new()
	r.position = pos
	r.size = size
	r.color = col
	return r

func _circle(radius: float, col: Color) -> Polygon2D:
	var p = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in 16:
		var a = i * TAU / 16.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	p.polygon = pts
	p.color = col
	return p

# === WEAPONS ===
func _do_weapon(d):
	sword_cd -= d
	if sword_cd <= 0:
		_swing_sword()
		sword_cd = 0.8

	if magic_level > 0:
		magic_cd -= d
		if magic_cd <= 0:
			_shoot_magic()
			magic_cd = 1.2

func _swing_sword():
	var nearest = _nearest_enemy()
	if not nearest or player.position.distance_to(nearest.position) > 120:
		return

	var dir = (nearest.position - player.position).normalized()

	# Visual slash
	var slash = Polygon2D.new()
	var pts = PackedVector2Array()
	pts.append(Vector2.ZERO)
	for i in 9:
		var a = -0.5 + i * 1.0 / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 50)
	slash.polygon = pts
	slash.color = Color(0.8, 0.8, 1.0, 0.7)
	slash.position = player.position + dir * 30
	slash.rotation = dir.angle()
	bullets.add_child(slash)

	# Hit enemies in range
	for e in enemies.get_children():
		if player.position.distance_to(e.position) < 70:
			_hit_enemy(e, damage)

	# Remove slash
	var tw = create_tween()
	tw.tween_property(slash, "modulate:a", 0.0, 0.15)
	tw.tween_callback(slash.queue_free)

func _shoot_magic():
	var target = _nearest_enemy()
	if not target:
		return

	var m = Node2D.new()
	m.position = player.position
	m.set_meta("target", target)
	m.set_meta("spd", 300.0)
	m.set_meta("dmg", damage * 0.8)

	var vis = Polygon2D.new()
	vis.polygon = PackedVector2Array([Vector2(-8,-4), Vector2(8,0), Vector2(-8,4)])
	vis.color = Color(0.4, 0.5, 0.95)
	m.add_child(vis)

	bullets.add_child(m)

func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := 99999.0
	for e in enemies.get_children():
		var d = player.position.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best

# === ENEMIES ===
var spawn_cd := 0.0
var enemy_types = ["skel", "zomb", "gobl"]

func _spawn_enemy():
	var angle = randf() * TAU
	var dist = randf_range(300, 450)
	var pos = player.position + Vector2(cos(angle), sin(angle)) * dist

	var type = enemy_types[randi() % enemy_types.size()]
	var e = Node2D.new()
	e.position = pos

	var data = _enemy_data(type)
	var scale_mult = 1.0 + game_time / 120.0
	e.set_meta("hp", data.hp * scale_mult)
	e.set_meta("spd", data.spd)
	e.set_meta("dmg", data.dmg * scale_mult)
	e.set_meta("xp", data.xp)
	e.set_meta("elite", false)

	var vis = _circle(data.size, data.col)
	e.add_child(vis)

	enemies.add_child(e)

func _spawn_elite():
	var angle = randf() * TAU
	var dist = randf_range(350, 500)
	var pos = player.position + Vector2(cos(angle), sin(angle)) * dist

	var e = Node2D.new()
	e.position = pos

	var scale_mult = 1.0 + game_time / 60.0
	e.set_meta("hp", 80.0 * scale_mult)
	e.set_meta("spd", 60.0)
	e.set_meta("dmg", 15.0 * scale_mult)
	e.set_meta("xp", 15)
	e.set_meta("elite", true)

	var vis = _circle(22, Color(1.0, 0.85, 0.3))
	e.add_child(vis)

	enemies.add_child(e)

func _enemy_data(type: String) -> Dictionary:
	match type:
		"skel": return {"hp": 12.0, "spd": 90.0, "dmg": 8.0, "xp": 1, "size": 12.0, "col": Color(0.85, 0.85, 0.8)}
		"zomb": return {"hp": 25.0, "spd": 45.0, "dmg": 12.0, "xp": 2, "size": 16.0, "col": Color(0.4, 0.5, 0.35)}
		"gobl": return {"hp": 8.0, "spd": 120.0, "dmg": 5.0, "xp": 1, "size": 10.0, "col": Color(0.3, 0.55, 0.3)}
		_: return {"hp": 12.0, "spd": 80.0, "dmg": 8.0, "xp": 1, "size": 12.0, "col": Color(0.7, 0.7, 0.7)}

func _do_enemies(d):
	for e in enemies.get_children():
		var dir = (player.position - e.position).normalized()
		e.position += dir * e.get_meta("spd") * d

		if e.position.distance_to(player.position) < 25:
			_take_hit(e.get_meta("dmg") * d * 2)

	# Update magic bullets
	for b in bullets.get_children():
		if b.has_meta("target"):
			var t = b.get_meta("target")
			if is_instance_valid(t):
				var dir = (t.position - b.position).normalized()
				b.position += dir * b.get_meta("spd") * d
				b.rotation = dir.angle()

				if b.position.distance_to(t.position) < 15:
					_hit_enemy(t, b.get_meta("dmg"))
					b.queue_free()
			else:
				b.queue_free()

func _hit_enemy(e: Node2D, dmg: float):
	if not is_instance_valid(e):
		return
	var h = e.get_meta("hp") - dmg
	e.set_meta("hp", h)

	if e.get_child_count() > 0:
		e.get_child(0).color = Color(1, 0.4, 0.4)

	if h <= 0:
		_kill_enemy(e)
	else:
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(e) and e.get_child_count() > 0:
			var is_elite = e.get_meta("elite")
			e.get_child(0).color = Color(1.0, 0.85, 0.3) if is_elite else Color(0.7, 0.7, 0.7)

func _kill_enemy(e: Node2D):
	kills += 1
	var xp_val = e.get_meta("xp")
	var pos = e.position
	var is_elite = e.get_meta("elite")

	_drop_xp(pos, xp_val)
	if randf() < 0.25 or is_elite:
		_drop_gold(pos)
	if is_elite and randf() < 0.4:
		_drop_chest(pos)

	e.queue_free()

func _do_spawn(d):
	spawn_cd -= d
	if spawn_cd <= 0 and enemies.get_child_count() < 80:
		var count = 2 + int(game_time / 25.0)
		for i in count:
			_spawn_enemy()

		if int(game_time) % 30 < 2 and game_time > 28:
			_spawn_elite()

		spawn_cd = max(0.4, 1.5 - game_time / 150.0)

# === DROPS ===
func _drop_xp(pos: Vector2, val: int):
	var d = Node2D.new()
	d.position = pos + Vector2(randf_range(-8,8), randf_range(-8,8))
	d.set_meta("type", "xp")
	d.set_meta("val", val)

	var v = Polygon2D.new()
	var sz = 5.0 + min(float(val), 8.0)
	v.polygon = PackedVector2Array([Vector2(0,-sz), Vector2(sz*0.5,0), Vector2(0,sz*0.4), Vector2(-sz*0.5,0)])
	v.color = Color(0.3, 0.85, 0.4) if val < 5 else Color(0.4, 0.5, 0.9)
	d.add_child(v)

	drops.add_child(d)

func _drop_gold(pos: Vector2):
	var d = Node2D.new()
	d.position = pos + Vector2(randf_range(-12,12), randf_range(-12,12))
	d.set_meta("type", "gold")

	var v = _circle(6, Color(1.0, 0.85, 0.2))
	d.add_child(v)

	drops.add_child(d)

func _drop_chest(pos: Vector2):
	var d = Node2D.new()
	d.position = pos
	d.set_meta("type", "chest")

	var body = _rect(Vector2(-14, 0), Vector2(28, 12), Color(0.5, 0.3, 0.15))
	d.add_child(body)
	var lid = _rect(Vector2(-14, -10), Vector2(28, 10), Color(0.6, 0.35, 0.2))
	d.add_child(lid)
	var trim = _rect(Vector2(-12, -2), Vector2(24, 4), Color(1.0, 0.85, 0.2))
	d.add_child(trim)

	drops.add_child(d)

func _do_drops():
	var range_dist = 70.0
	for d in drops.get_children():
		var dist = player.position.distance_to(d.position)

		if dist < range_dist:
			var dir = (player.position - d.position).normalized()
			d.position += dir * 350 * get_process_delta_time()

		if dist < 20:
			var type = d.get_meta("type")
			if type == "xp":
				_add_xp(d.get_meta("val"))
			elif type == "chest":
				_open_chest()
			d.queue_free()

func _open_chest():
	var count = 1
	if randf() < 0.15 * luck: count = 2
	if randf() < 0.03 * luck: count = 3

	for i in count:
		var r = randi() % 4
		match r:
			0: damage += 2
			1: max_hp += 10; hp += 10
			2: speed += 12
			3: luck += 0.15

# === XP / LEVEL ===
func _add_xp(val: int):
	xp += val
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		xp_need = int(10.0 * pow(float(level), 1.35))
		_show_levelup()

func _show_levelup():
	paused = true
	lvlup_ui.visible = true

	var opts = [
		{"txt": "Damage +15%", "fn": func(): damage *= 1.15},
		{"txt": "Max HP +20", "fn": func(): max_hp += 20; hp += 20},
		{"txt": "Speed +12%", "fn": func(): speed *= 1.12},
		{"txt": "Luck +0.25", "fn": func(): luck += 0.25},
		{"txt": "Sword damage +20%", "fn": func(): damage *= 1.2},
	]

	if magic_level == 0:
		opts.append({"txt": "NEW: Magic Missile", "fn": func(): magic_level = 1})
	else:
		opts.append({"txt": "Magic upgrade", "fn": func(): magic_level += 1})

	opts.shuffle()

	for i in 3:
		var b = lvlup_ui.get_node("U" + str(i))
		b.text = opts[i].txt
		for c in b.pressed.get_connections():
			b.pressed.disconnect(c.callable)
		b.pressed.connect(_pick_upgrade.bind(opts[i].fn))

func _pick_upgrade(fn: Callable):
	fn.call()
	lvlup_ui.visible = false
	paused = false

# === DAMAGE ===
func _take_hit(dmg: float):
	hp -= dmg
	if hp <= 0:
		hp = 0
		_game_over()

func _game_over():
	playing = false
	over_ui.visible = true
	var m = int(game_time) / 60
	var s = int(game_time) % 60
	over_lbl.text = "GAME OVER\n\nTime: %02d:%02d\nLevel: %d\nKills: %d" % [m, s, level, kills]
