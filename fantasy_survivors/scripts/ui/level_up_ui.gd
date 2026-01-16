extends CanvasLayer
class_name LevelUpUI
## LevelUpUI - Shows upgrade choices when player levels up

signal upgrade_selected(upgrade: Dictionary)

@export var container: VBoxContainer
@export var title_label: Label
@export var options_container: HBoxContainer

var pending_level_ups: int = 0
var current_options: Array[Dictionary] = []

# All possible upgrades
var upgrade_pool: Array[Dictionary] = [
	# Weapon upgrades
	{"type": "weapon", "id": "sword_slash", "name": "Sword Slash", "desc": "Upgrade sword damage and range", "icon_color": Color(0.8, 0.8, 0.9)},
	{"type": "weapon", "id": "magic_missile", "name": "Magic Missile", "desc": "Upgrade homing missiles", "icon_color": Color(0.4, 0.6, 1.0)},
	{"type": "weapon", "id": "arrow_volley", "name": "Arrow Volley", "desc": "Upgrade arrow count and pierce", "icon_color": Color(0.6, 0.4, 0.2)},
	{"type": "weapon", "id": "holy_smite", "name": "Holy Smite", "desc": "Divine AoE damage", "icon_color": Color(1.0, 0.95, 0.6)},
	{"type": "weapon", "id": "soul_drain", "name": "Soul Drain", "desc": "Lifesteal projectiles", "icon_color": Color(0.5, 0.2, 0.6)},
	{"type": "weapon", "id": "axe_throw", "name": "Axe Throw", "desc": "Boomerang axes", "icon_color": Color(0.7, 0.3, 0.2)},
	{"type": "weapon", "id": "fire_circle", "name": "Fire Circle", "desc": "Orbiting fireballs", "icon_color": Color(1.0, 0.5, 0.1)},
	{"type": "weapon", "id": "lightning_bolt", "name": "Lightning Bolt", "desc": "Chain lightning strikes", "icon_color": Color(0.3, 0.8, 1.0)},

	# Stat upgrades
	{"type": "stat", "id": "damage", "name": "Might", "desc": "+10% Damage", "stat": "damage", "value": 0.1, "mult": true, "icon_color": Color(1.0, 0.3, 0.3)},
	{"type": "stat", "id": "max_health", "name": "Vitality", "desc": "+20 Max HP", "stat": "max_health", "value": 20, "mult": false, "icon_color": Color(0.3, 0.9, 0.3)},
	{"type": "stat", "id": "armor", "name": "Armor", "desc": "+5 Armor", "stat": "armor", "value": 5, "mult": false, "icon_color": Color(0.6, 0.6, 0.7)},
	{"type": "stat", "id": "move_speed", "name": "Swiftness", "desc": "+8% Speed", "stat": "move_speed", "value": 0.08, "mult": true, "icon_color": Color(0.3, 0.7, 1.0)},
	{"type": "stat", "id": "attack_speed", "name": "Haste", "desc": "+10% Attack Speed", "stat": "attack_speed", "value": 0.1, "mult": false, "icon_color": Color(0.9, 0.9, 0.3)},
	{"type": "stat", "id": "crit_chance", "name": "Precision", "desc": "+5% Crit Chance", "stat": "crit_chance", "value": 0.05, "mult": false, "icon_color": Color(1.0, 0.5, 0.0)},
	{"type": "stat", "id": "health_regen", "name": "Recovery", "desc": "+0.5 HP/s Regen", "stat": "health_regen", "value": 0.5, "mult": false, "icon_color": Color(0.4, 1.0, 0.4)},
	{"type": "stat", "id": "luck", "name": "Fortune", "desc": "+0.2 Luck", "stat": "luck", "value": 0.2, "mult": false, "icon_color": Color(1.0, 0.9, 0.3)},
	{"type": "stat", "id": "xp_mult", "name": "Wisdom", "desc": "+10% XP Gain", "stat": "xp_multiplier", "value": 0.1, "mult": false, "icon_color": Color(0.6, 0.3, 0.9)},
	{"type": "stat", "id": "pickup_range", "name": "Magnet", "desc": "+25 Pickup Range", "stat": "pickup_range", "value": 25, "mult": false, "icon_color": Color(0.8, 0.5, 1.0)},
]

func _ready() -> void:
	visible = false
	PlayerStats.level_up.connect(_on_level_up)

func _on_level_up(new_level: int) -> void:
	pending_level_ups += 1
	if not visible:
		_show_upgrade_choices()

func _show_upgrade_choices() -> void:
	visible = true
	_generate_options()
	_display_options()

func _generate_options() -> void:
	current_options.clear()
	var player = get_tree().get_first_node_in_group("player")
	var player_weapons = []
	if player:
		player_weapons = player.get_all_weapons().map(func(w): return w.weapon_id)

	# Build weighted pool
	var available_upgrades: Array[Dictionary] = []

	for upgrade in upgrade_pool:
		if upgrade["type"] == "weapon":
			# If player has weapon, it's an upgrade
			# If not, it's a new weapon (lower priority)
			if upgrade["id"] in player_weapons:
				var weapon = player.get_weapon(upgrade["id"])
				if weapon and weapon.level < weapon.max_level:
					var u = upgrade.duplicate()
					u["is_upgrade"] = true
					u["current_level"] = weapon.level
					available_upgrades.append(u)
			else:
				var u = upgrade.duplicate()
				u["is_upgrade"] = false
				available_upgrades.append(u)
		else:
			available_upgrades.append(upgrade)

	# Shuffle and pick 3
	available_upgrades.shuffle()
	current_options = available_upgrades.slice(0, 3)

func _display_options() -> void:
	# Clear existing options
	if options_container:
		for child in options_container.get_children():
			child.queue_free()

	# Create option buttons
	for i in current_options.size():
		var option = current_options[i]
		var button = _create_option_button(option, i)
		options_container.add_child(button)

func _create_option_button(option: Dictionary, index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 300)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Icon placeholder
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.color = option.get("icon_color", Color.WHITE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	# Name
	var name_label = Label.new()
	name_label.text = option["name"]
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = option["desc"]
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# Level indicator for weapons
	if option["type"] == "weapon" and option.get("is_upgrade", false):
		var level_label = Label.new()
		level_label.text = "Level %d → %d" % [option["current_level"], option["current_level"] + 1]
		level_label.add_theme_font_size_override("font_size", 14)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		vbox.add_child(level_label)

	# Make clickable
	var button = Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.pressed.connect(_on_option_selected.bind(index))
	panel.add_child(button)

	return panel

func _on_option_selected(index: int) -> void:
	var option = current_options[index]
	_apply_upgrade(option)
	upgrade_selected.emit(option)

	pending_level_ups -= 1
	if pending_level_ups > 0:
		_show_upgrade_choices()
	else:
		_hide()

func _apply_upgrade(option: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")

	if option["type"] == "weapon":
		if player:
			player.add_weapon(option["id"])
	elif option["type"] == "stat":
		PlayerStats.modify_stat(option["stat"], option["value"], option.get("mult", false))

func _hide() -> void:
	visible = false
	GameManager.resume_game()
