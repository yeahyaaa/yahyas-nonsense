extends Node
## PlayerStats - Manages player statistics, XP, luck, and progression

signal xp_gained(amount: int)
signal level_up(new_level: int)
signal gold_gained(amount: int)
signal stat_changed(stat_name: String, new_value: float)
signal health_changed(current: float, maximum: float)

# Base stats (modified by class and meta upgrades)
var base_stats: Dictionary = {
	"max_health": 100.0,
	"health_regen": 0.5,
	"move_speed": 200.0,
	"damage": 10.0,
	"attack_speed": 1.0,
	"armor": 0.0,
	"luck": 1.0,           # Affects chest drops (1-3 powerups)
	"xp_multiplier": 1.0,
	"pickup_range": 50.0,
	"crit_chance": 0.05,
	"crit_damage": 1.5
}

# Current run stats (reset each run)
var current_stats: Dictionary = {}
var current_health: float = 100.0
var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = 10
var kills: int = 0
var chests_opened: int = 0
var run_gold: int = 0

# Persistent stats (saved between runs)
var total_gold: int = 0
var highest_level: int = 1
var total_kills: int = 0
var unlocked_characters: Array[String] = ["knight"]
var unlocked_cosmetics: Dictionary = {
	"body_types": ["athletic"],
	"races": ["human"],
	"hair_styles": ["short"],
	"armor_sets": ["basic"]
}

# Meta upgrades (permanent bonuses bought with gold)
var meta_upgrades: Dictionary = {
	"max_health": 0,      # Each level = +10 HP
	"damage": 0,          # Each level = +5% damage
	"move_speed": 0,      # Each level = +3% speed
	"luck": 0,            # Each level = +0.1 luck
	"xp_gain": 0,         # Each level = +5% XP
	"armor": 0,           # Each level = +2 armor
	"starting_weapon": 0  # Each level = +1 starting weapon level
}

# Current character selection
var selected_class: String = "knight"
var character_customization: Dictionary = {
	"body_type": "athletic",
	"race": "human",
	"skin_color": Color(0.9, 0.75, 0.65),
	"hair_style": "short",
	"hair_color": Color(0.3, 0.2, 0.1),
	"armor_set": "basic",
	"primary_color": Color(0.5, 0.5, 0.6),
	"secondary_color": Color(0.3, 0.3, 0.35)
}

# Class definitions
var classes: Dictionary = {
	"knight": {
		"name": "Knight",
		"starting_weapon": "sword_slash",
		"passive": "defense_boost",
		"passive_value": 0.2,
		"description": "+20% Defense"
	},
	"mage": {
		"name": "Mage",
		"starting_weapon": "magic_missile",
		"passive": "xp_boost",
		"passive_value": 0.15,
		"description": "+15% XP Gain"
	},
	"archer": {
		"name": "Archer",
		"starting_weapon": "arrow_volley",
		"passive": "speed_boost",
		"passive_value": 0.1,
		"description": "+10% Move Speed"
	},
	"cleric": {
		"name": "Cleric",
		"starting_weapon": "holy_smite",
		"passive": "health_regen",
		"passive_value": 1.0,
		"description": "Life Regeneration"
	},
	"necromancer": {
		"name": "Necromancer",
		"starting_weapon": "soul_drain",
		"passive": "summon_skeletons",
		"passive_value": 2,
		"description": "Summon Skeletons"
	},
	"barbarian": {
		"name": "Barbarian",
		"starting_weapon": "axe_throw",
		"passive": "rage",
		"passive_value": 0.5,
		"description": "Rage when low HP"
	}
}

func _ready() -> void:
	reset_run_stats()
	load_save_data()

func reset_run_stats() -> void:
	current_stats = base_stats.duplicate()
	apply_meta_upgrades()
	apply_class_bonuses()
	current_health = current_stats["max_health"]
	current_xp = 0
	current_level = 1
	xp_to_next_level = 10
	kills = 0
	chests_opened = 0
	run_gold = 0

func apply_meta_upgrades() -> void:
	current_stats["max_health"] += meta_upgrades["max_health"] * 10
	current_stats["damage"] *= 1.0 + (meta_upgrades["damage"] * 0.05)
	current_stats["move_speed"] *= 1.0 + (meta_upgrades["move_speed"] * 0.03)
	current_stats["luck"] += meta_upgrades["luck"] * 0.1
	current_stats["xp_multiplier"] *= 1.0 + (meta_upgrades["xp_gain"] * 0.05)
	current_stats["armor"] += meta_upgrades["armor"] * 2

func apply_class_bonuses() -> void:
	var class_data = classes.get(selected_class, classes["knight"])
	match class_data["passive"]:
		"defense_boost":
			current_stats["armor"] += current_stats["max_health"] * class_data["passive_value"]
		"xp_boost":
			current_stats["xp_multiplier"] *= 1.0 + class_data["passive_value"]
		"speed_boost":
			current_stats["move_speed"] *= 1.0 + class_data["passive_value"]
		"health_regen":
			current_stats["health_regen"] += class_data["passive_value"]

func get_stat(stat_name: String) -> float:
	return current_stats.get(stat_name, 0.0)

func modify_stat(stat_name: String, modifier: float, is_multiplier: bool = false) -> void:
	if stat_name in current_stats:
		if is_multiplier:
			current_stats[stat_name] *= modifier
		else:
			current_stats[stat_name] += modifier
		stat_changed.emit(stat_name, current_stats[stat_name])

func take_damage(amount: float) -> void:
	var actual_damage = max(1, amount - current_stats["armor"])
	current_health = max(0, current_health - actual_damage)
	health_changed.emit(current_health, current_stats["max_health"])
	if current_health <= 0:
		GameManager.trigger_game_over(false)

func heal(amount: float) -> void:
	current_health = min(current_stats["max_health"], current_health + amount)
	health_changed.emit(current_health, current_stats["max_health"])

func add_xp(amount: int) -> void:
	var actual_xp = int(amount * current_stats["xp_multiplier"])
	current_xp += actual_xp
	xp_gained.emit(actual_xp)

	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		xp_to_next_level = calculate_xp_for_level(current_level)
		level_up.emit(current_level)

func calculate_xp_for_level(level: int) -> int:
	return int(10 * pow(level, 1.5))

func add_gold(amount: int) -> void:
	run_gold += amount
	gold_gained.emit(amount)

func add_kill() -> void:
	kills += 1

func calculate_chest_powerups() -> int:
	# Luck affects number of powerups (1-3)
	# Base chance: 1 powerup always
	# Luck 1.0 = ~10% for 2, ~1% for 3
	# Luck 2.0 = ~30% for 2, ~10% for 3
	# Luck 3.0+ = ~50% for 2, ~25% for 3
	var luck = current_stats["luck"]
	var roll = randf()

	var chance_for_3 = min(0.25, 0.01 * luck * luck)
	var chance_for_2 = min(0.5, 0.1 * luck)

	if roll < chance_for_3:
		return 3
	elif roll < chance_for_3 + chance_for_2:
		return 2
	else:
		return 1

func end_run() -> void:
	total_gold += run_gold
	total_kills += kills
	if current_level > highest_level:
		highest_level = current_level
	save_data()

func unlock_character(character_id: String) -> void:
	if character_id not in unlocked_characters:
		unlocked_characters.append(character_id)
		save_data()

func unlock_cosmetic(category: String, item_id: String) -> void:
	if category in unlocked_cosmetics:
		if item_id not in unlocked_cosmetics[category]:
			unlocked_cosmetics[category].append(item_id)
			save_data()

func purchase_meta_upgrade(upgrade_id: String, cost: int) -> bool:
	if total_gold >= cost and upgrade_id in meta_upgrades:
		total_gold -= cost
		meta_upgrades[upgrade_id] += 1
		save_data()
		return true
	return false

func get_meta_upgrade_cost(upgrade_id: String) -> int:
	var level = meta_upgrades.get(upgrade_id, 0)
	return int(100 * pow(1.5, level))

func save_data() -> void:
	SaveManager.save_player_data(self)

func load_save_data() -> void:
	SaveManager.load_player_data(self)

func get_class_data(class_id: String = "") -> Dictionary:
	if class_id.is_empty():
		class_id = selected_class
	return classes.get(class_id, classes["knight"])
