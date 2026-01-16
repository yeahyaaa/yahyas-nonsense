extends Control
class_name MetaShop
## MetaShop - Permanent upgrades purchased with gold

@export var gold_label: Label
@export var upgrades_container: GridContainer
@export var back_button: Button
@export var purchase_feedback: Label

var upgrade_definitions: Array[Dictionary] = [
	{
		"id": "max_health",
		"name": "Vitality",
		"description": "+10 Max HP per level",
		"icon_color": Color(0.3, 0.9, 0.3),
		"max_level": 10
	},
	{
		"id": "damage",
		"name": "Might",
		"description": "+5% Damage per level",
		"icon_color": Color(1.0, 0.3, 0.3),
		"max_level": 10
	},
	{
		"id": "move_speed",
		"name": "Swiftness",
		"description": "+3% Move Speed per level",
		"icon_color": Color(0.3, 0.7, 1.0),
		"max_level": 10
	},
	{
		"id": "luck",
		"name": "Fortune",
		"description": "+0.1 Luck per level",
		"icon_color": Color(1.0, 0.9, 0.3),
		"max_level": 10
	},
	{
		"id": "xp_gain",
		"name": "Wisdom",
		"description": "+5% XP Gain per level",
		"icon_color": Color(0.6, 0.3, 0.9),
		"max_level": 10
	},
	{
		"id": "armor",
		"name": "Fortitude",
		"description": "+2 Armor per level",
		"icon_color": Color(0.6, 0.6, 0.7),
		"max_level": 10
	},
	{
		"id": "starting_weapon",
		"name": "Preparation",
		"description": "+1 Starting Weapon Level",
		"icon_color": Color(0.8, 0.5, 0.2),
		"max_level": 3
	}
]

func _ready() -> void:
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	_update_gold_display()
	_create_upgrade_cards()

func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % PlayerStats.total_gold

func _create_upgrade_cards() -> void:
	if not upgrades_container:
		return

	for child in upgrades_container.get_children():
		child.queue_free()

	for upgrade in upgrade_definitions:
		var card = _create_upgrade_card(upgrade)
		upgrades_container.add_child(card)

func _create_upgrade_card(upgrade: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 250)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# Icon
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(60, 60)
	icon.color = upgrade["icon_color"]
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	# Name
	var name_label = Label.new()
	name_label.text = upgrade["name"]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade["description"]
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# Level progress
	var current_level = PlayerStats.meta_upgrades.get(upgrade["id"], 0)
	var level_label = Label.new()
	level_label.text = "Level: %d / %d" % [current_level, upgrade["max_level"]]
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_label)

	# Progress bar
	var progress = ProgressBar.new()
	progress.max_value = upgrade["max_level"]
	progress.value = current_level
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(progress)

	# Buy button
	var buy_button = Button.new()
	var cost = PlayerStats.get_meta_upgrade_cost(upgrade["id"])
	var is_maxed = current_level >= upgrade["max_level"]
	var can_afford = PlayerStats.total_gold >= cost

	if is_maxed:
		buy_button.text = "MAXED"
		buy_button.disabled = true
	else:
		buy_button.text = "Buy: %d Gold" % cost
		buy_button.disabled = not can_afford

	buy_button.pressed.connect(_on_upgrade_purchased.bind(upgrade["id"]))
	vbox.add_child(buy_button)

	return card

func _on_upgrade_purchased(upgrade_id: String) -> void:
	var cost = PlayerStats.get_meta_upgrade_cost(upgrade_id)

	if PlayerStats.purchase_meta_upgrade(upgrade_id, cost):
		_show_feedback("Upgrade purchased!")
		_setup_ui()
	else:
		_show_feedback("Not enough gold!")

func _show_feedback(message: String) -> void:
	if purchase_feedback:
		purchase_feedback.text = message
		purchase_feedback.visible = true

		var tween = create_tween()
		tween.tween_property(purchase_feedback, "modulate:a", 0.0, 1.0).set_delay(1.0)
		await tween.finished
		purchase_feedback.visible = false
		purchase_feedback.modulate.a = 1.0

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
