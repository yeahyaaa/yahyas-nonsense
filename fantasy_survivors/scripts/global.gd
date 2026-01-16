extends Node
## Global - Manages all game state, stats, and persistence

# Signals
signal health_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int)
signal level_up(new_level: int)
signal gold_changed(amount: int)
signal game_over(victory: bool)
signal enemy_killed(enemy_type: String, is_elite: bool)

# Game State
enum State { MENU, PLAYING, PAUSED, LEVEL_UP, GAME_OVER, VICTORY }
var state: State = State.MENU
var game_time: float = 0.0
var current_stage: int = 1

# Player Stats - Current Run
var max_health: float = 100.0
var current_health: float = 100.0
var move_speed: float = 250.0
var damage_mult: float = 1.0
var attack_speed: float = 1.0
var armor: float = 0.0
var luck: float = 1.0
var xp_mult: float = 1.0
var pickup_range: float = 80.0
var health_regen: float = 0.0
var crit_chance: float = 0.05
var crit_damage: float = 1.5

# XP & Level
var current_xp: int = 0
var current_level: int = 1
var xp_to_level: int = 10

# Run Stats
var kills: int = 0
var run_gold: int = 0
var chests_opened: int = 0

# Persistent Stats (saved)
var total_gold: int = 0
var highest_level: int = 1
var total_kills: int = 0
var stages_completed: Array[int] = []

# Meta Upgrades
var meta_health: int = 0
var meta_damage: int = 0
var meta_speed: int = 0
var meta_luck: int = 0
var meta_xp: int = 0
var meta_armor: int = 0

# Selected Class
var selected_class: String = "knight"

# Class Definitions
var classes: Dictionary = {
	"knight": {"name": "Knight", "weapon": "sword", "passive": "armor", "passive_value": 5.0, "desc": "+5 Armor"},
	"mage": {"name": "Mage", "weapon": "magic", "passive": "xp", "passive_value": 0.2, "desc": "+20% XP"},
	"archer": {"name": "Archer", "weapon": "arrow", "passive": "speed", "passive_value": 30.0, "desc": "+30 Speed"},
}

# Weapon Pool
var all_weapons: Array[String] = ["sword", "magic", "arrow", "fire_orbit", "lightning", "holy"]

# Current weapons
var player_weapons: Dictionary = {}  # weapon_id -> level

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	if state == State.PLAYING:
		game_time += delta

# ============ GAME FLOW ============

func start_game() -> void:
	reset_run_stats()
	apply_meta_upgrades()
	apply_class_bonus()
	current_health = max_health
	state = State.PLAYING

	# Give starting weapon
	var class_data = classes[selected_class]
	player_weapons[class_data["weapon"]] = 1

func reset_run_stats() -> void:
	max_health = 100.0
	current_health = 100.0
	move_speed = 250.0
	damage_mult = 1.0
	attack_speed = 1.0
	armor = 0.0
	luck = 1.0
	xp_mult = 1.0
	pickup_range = 80.0
	health_regen = 0.0
	crit_chance = 0.05
	crit_damage = 1.5
	current_xp = 0
	current_level = 1
	xp_to_level = 10
	kills = 0
	run_gold = 0
	chests_opened = 0
	game_time = 0.0
	player_weapons.clear()

func apply_meta_upgrades() -> void:
	max_health += meta_health * 10
	damage_mult += meta_damage * 0.05
	move_speed += meta_speed * 10
	luck += meta_luck * 0.15
	xp_mult += meta_xp * 0.08
	armor += meta_armor * 2

func apply_class_bonus() -> void:
	var class_data = classes[selected_class]
	match class_data["passive"]:
		"armor": armor += class_data["passive_value"]
		"xp": xp_mult += class_data["passive_value"]
		"speed": move_speed += class_data["passive_value"]

func pause_game() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true

func resume_game() -> void:
	if state == State.PAUSED or state == State.LEVEL_UP:
		state = State.PLAYING
		get_tree().paused = false

func trigger_game_over(victory: bool) -> void:
	state = State.VICTORY if victory else State.GAME_OVER
	end_run()
	game_over.emit(victory)

func end_run() -> void:
	total_gold += run_gold
	total_kills += kills
	if current_level > highest_level:
		highest_level = current_level
	save_game()

# ============ COMBAT ============

func take_damage(amount: float) -> void:
	var actual = max(1.0, amount - armor)
	current_health = max(0.0, current_health - actual)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		trigger_game_over(false)

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func add_xp(amount: int) -> void:
	var actual = int(amount * xp_mult)
	current_xp += actual

	while current_xp >= xp_to_level:
		current_xp -= xp_to_level
		current_level += 1
		xp_to_level = int(10 * pow(current_level, 1.4))
		state = State.LEVEL_UP
		get_tree().paused = true
		level_up.emit(current_level)

	xp_changed.emit(current_xp, xp_to_level)

func add_gold(amount: int) -> void:
	run_gold += amount
	gold_changed.emit(run_gold)

func add_kill(enemy_type: String, is_elite: bool) -> void:
	kills += 1
	enemy_killed.emit(enemy_type, is_elite)

# ============ UPGRADES ============

func get_upgrade_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	# Weapon upgrades for owned weapons
	for weapon_id in player_weapons:
		if player_weapons[weapon_id] < 8:
			options.append({
				"type": "weapon_upgrade",
				"id": weapon_id,
				"name": _get_weapon_name(weapon_id) + " Lv" + str(player_weapons[weapon_id] + 1),
				"desc": "Upgrade " + _get_weapon_name(weapon_id),
				"color": _get_weapon_color(weapon_id)
			})

	# New weapons
	for weapon_id in all_weapons:
		if weapon_id not in player_weapons and options.size() < 6:
			options.append({
				"type": "new_weapon",
				"id": weapon_id,
				"name": _get_weapon_name(weapon_id),
				"desc": "New weapon: " + _get_weapon_name(weapon_id),
				"color": _get_weapon_color(weapon_id)
			})

	# Stat upgrades
	var stat_upgrades = [
		{"type": "stat", "id": "health", "name": "+20 Max HP", "desc": "Increase max health", "color": Color(0.3, 0.9, 0.3)},
		{"type": "stat", "id": "damage", "name": "+10% Damage", "desc": "Increase all damage", "color": Color(0.9, 0.3, 0.3)},
		{"type": "stat", "id": "speed", "name": "+15 Speed", "desc": "Move faster", "color": Color(0.3, 0.6, 0.9)},
		{"type": "stat", "id": "armor", "name": "+3 Armor", "desc": "Reduce damage taken", "color": Color(0.6, 0.6, 0.7)},
		{"type": "stat", "id": "luck", "name": "+0.3 Luck", "desc": "Better chest drops", "color": Color(0.9, 0.8, 0.2)},
		{"type": "stat", "id": "regen", "name": "+0.5 HP/s", "desc": "Health regeneration", "color": Color(0.4, 0.9, 0.4)},
		{"type": "stat", "id": "crit", "name": "+5% Crit", "desc": "Critical hit chance", "color": Color(0.9, 0.5, 0.2)},
	]
	options.append_array(stat_upgrades)

	options.shuffle()
	return options.slice(0, 3)

func apply_upgrade(upgrade: Dictionary) -> void:
	match upgrade["type"]:
		"weapon_upgrade":
			player_weapons[upgrade["id"]] += 1
		"new_weapon":
			player_weapons[upgrade["id"]] = 1
		"stat":
			match upgrade["id"]:
				"health":
					max_health += 20
					current_health += 20
					health_changed.emit(current_health, max_health)
				"damage": damage_mult += 0.1
				"speed": move_speed += 15
				"armor": armor += 3
				"luck": luck += 0.3
				"regen": health_regen += 0.5
				"crit": crit_chance += 0.05

func _get_weapon_name(id: String) -> String:
	match id:
		"sword": return "Sword Slash"
		"magic": return "Magic Missile"
		"arrow": return "Arrow Volley"
		"fire_orbit": return "Fire Orbit"
		"lightning": return "Lightning"
		"holy": return "Holy Smite"
		_: return id.capitalize()

func _get_weapon_color(id: String) -> Color:
	match id:
		"sword": return Color(0.7, 0.7, 0.8)
		"magic": return Color(0.4, 0.5, 0.9)
		"arrow": return Color(0.6, 0.4, 0.2)
		"fire_orbit": return Color(0.9, 0.4, 0.1)
		"lightning": return Color(0.3, 0.7, 0.9)
		"holy": return Color(0.9, 0.9, 0.5)
		_: return Color.WHITE

# ============ CHEST SYSTEM ============

func calculate_chest_powerups() -> int:
	var roll = randf()
	var chance_3 = min(0.25, 0.02 * luck * luck)
	var chance_2 = min(0.5, 0.1 * luck)

	if roll < chance_3:
		return 3
	elif roll < chance_3 + chance_2:
		return 2
	return 1

func get_random_powerup() -> Dictionary:
	var powerups = [
		{"name": "+10% Damage", "stat": "damage_mult", "value": 0.1},
		{"name": "+15 Max HP", "stat": "max_health", "value": 15.0},
		{"name": "+10 Speed", "stat": "move_speed", "value": 10.0},
		{"name": "+2 Armor", "stat": "armor", "value": 2.0},
		{"name": "+0.2 Luck", "stat": "luck", "value": 0.2},
		{"name": "+5% Attack Speed", "stat": "attack_speed", "value": 0.05},
		{"name": "+3% Crit", "stat": "crit_chance", "value": 0.03},
		{"name": "+0.3 HP/s", "stat": "health_regen", "value": 0.3},
	]
	return powerups[randi() % powerups.size()]

func apply_powerup(powerup: Dictionary) -> void:
	set(powerup["stat"], get(powerup["stat"]) + powerup["value"])
	if powerup["stat"] == "max_health":
		current_health += powerup["value"]
		health_changed.emit(current_health, max_health)

# ============ META SHOP ============

func get_meta_cost(upgrade_id: String) -> int:
	var level = get("meta_" + upgrade_id)
	return int(50 * pow(1.5, level))

func buy_meta_upgrade(upgrade_id: String) -> bool:
	var cost = get_meta_cost(upgrade_id)
	if total_gold >= cost:
		total_gold -= cost
		set("meta_" + upgrade_id, get("meta_" + upgrade_id) + 1)
		save_game()
		return true
	return false

# ============ SAVE/LOAD ============

func save_game() -> void:
	var data = {
		"total_gold": total_gold,
		"highest_level": highest_level,
		"total_kills": total_kills,
		"stages_completed": stages_completed,
		"meta_health": meta_health,
		"meta_damage": meta_damage,
		"meta_speed": meta_speed,
		"meta_luck": meta_luck,
		"meta_xp": meta_xp,
		"meta_armor": meta_armor,
		"selected_class": selected_class
	}
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game() -> void:
	if FileAccess.file_exists("user://save.json"):
		var file = FileAccess.open("user://save.json", FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data:
				total_gold = data.get("total_gold", 0)
				highest_level = data.get("highest_level", 1)
				total_kills = data.get("total_kills", 0)
				meta_health = data.get("meta_health", 0)
				meta_damage = data.get("meta_damage", 0)
				meta_speed = data.get("meta_speed", 0)
				meta_luck = data.get("meta_luck", 0)
				meta_xp = data.get("meta_xp", 0)
				meta_armor = data.get("meta_armor", 0)
				selected_class = data.get("selected_class", "knight")

# ============ UTILS ============

func get_formatted_time() -> String:
	var mins = int(game_time) / 60
	var secs = int(game_time) % 60
	return "%02d:%02d" % [mins, secs]
