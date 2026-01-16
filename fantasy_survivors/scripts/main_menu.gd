extends Control
class_name MainMenu

var title_label: Label
var play_btn: Button
var class_btn: Button
var shop_btn: Button
var gold_label: Label
var stats_label: Label
var class_panel: Control
var shop_panel: Control

# Class selection
var class_buttons: Array[Button] = []
var selected_class_label: Label

# Shop
var shop_items: Array[Dictionary] = []
var shop_buttons: Array[Button] = []

func _ready() -> void:
	_create_ui()
	_update_display()

func _create_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0.08, 0.09, 0.12)
	add_child(bg)

	# Title
	title_label = Label.new()
	title_label.position = Vector2(200, 200)
	title_label.text = "FANTASY\nSURVIVORS"
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	add_child(title_label)

	# Play button
	play_btn = Button.new()
	play_btn.position = Vector2(290, 550)
	play_btn.size = Vector2(500, 120)
	play_btn.text = "PLAY"
	play_btn.add_theme_font_size_override("font_size", 40)
	play_btn.pressed.connect(_on_play_pressed)
	add_child(play_btn)

	# Class selection button
	class_btn = Button.new()
	class_btn.position = Vector2(290, 720)
	class_btn.size = Vector2(500, 90)
	class_btn.text = "SELECT CLASS"
	class_btn.add_theme_font_size_override("font_size", 28)
	class_btn.pressed.connect(_on_class_pressed)
	add_child(class_btn)

	# Shop button
	shop_btn = Button.new()
	shop_btn.position = Vector2(290, 850)
	shop_btn.size = Vector2(500, 90)
	shop_btn.text = "UPGRADES"
	shop_btn.add_theme_font_size_override("font_size", 28)
	shop_btn.pressed.connect(_on_shop_pressed)
	add_child(shop_btn)

	# Gold display
	gold_label = Label.new()
	gold_label.position = Vector2(400, 1000)
	gold_label.add_theme_font_size_override("font_size", 32)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(gold_label)

	# Stats display
	stats_label = Label.new()
	stats_label.position = Vector2(350, 1100)
	stats_label.add_theme_font_size_override("font_size", 22)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(stats_label)

	# Class selection panel (hidden by default)
	_create_class_panel()

	# Shop panel (hidden by default)
	_create_shop_panel()

func _create_class_panel() -> void:
	class_panel = Control.new()
	class_panel.visible = false
	add_child(class_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0, 0, 0, 0.9)
	class_panel.add_child(bg)

	var title = Label.new()
	title.position = Vector2(350, 150)
	title.text = "SELECT CLASS"
	title.add_theme_font_size_override("font_size", 40)
	class_panel.add_child(title)

	selected_class_label = Label.new()
	selected_class_label.position = Vector2(300, 250)
	selected_class_label.add_theme_font_size_override("font_size", 24)
	class_panel.add_child(selected_class_label)

	var classes = ["knight", "mage", "archer"]
	for i in classes.size():
		var class_id = classes[i]
		var class_data = Global.classes[class_id]

		var btn = Button.new()
		btn.position = Vector2(190, 350 + i * 200)
		btn.size = Vector2(700, 160)
		btn.text = class_data["name"] + "\n\n" + class_data["desc"]
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_class_selected.bind(class_id))
		class_panel.add_child(btn)
		class_buttons.append(btn)

	var back_btn = Button.new()
	back_btn.position = Vector2(340, 1000)
	back_btn.size = Vector2(400, 80)
	back_btn.text = "BACK"
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(func(): class_panel.visible = false)
	class_panel.add_child(back_btn)

func _create_shop_panel() -> void:
	shop_panel = Control.new()
	shop_panel.visible = false
	add_child(shop_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0, 0, 0, 0.9)
	shop_panel.add_child(bg)

	var title = Label.new()
	title.position = Vector2(380, 100)
	title.text = "UPGRADES"
	title.add_theme_font_size_override("font_size", 40)
	shop_panel.add_child(title)

	var gold = Label.new()
	gold.name = "ShopGold"
	gold.position = Vector2(420, 170)
	gold.add_theme_font_size_override("font_size", 28)
	gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	shop_panel.add_child(gold)

	shop_items = [
		{"id": "health", "name": "Max Health", "desc": "+10 HP per level"},
		{"id": "damage", "name": "Damage", "desc": "+5% damage per level"},
		{"id": "speed", "name": "Speed", "desc": "+10 speed per level"},
		{"id": "luck", "name": "Luck", "desc": "+0.15 luck per level"},
		{"id": "xp", "name": "XP Gain", "desc": "+8% XP per level"},
		{"id": "armor", "name": "Armor", "desc": "+2 armor per level"},
	]

	for i in shop_items.size():
		var item = shop_items[i]
		var btn = Button.new()
		btn.name = "ShopBtn_" + item["id"]
		btn.position = Vector2(90 + (i % 2) * 450, 280 + int(i / 2) * 180)
		btn.size = Vector2(420, 150)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_shop_buy.bind(item["id"]))
		shop_panel.add_child(btn)
		shop_buttons.append(btn)

	var back_btn = Button.new()
	back_btn.position = Vector2(340, 900)
	back_btn.size = Vector2(400, 80)
	back_btn.text = "BACK"
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(_on_shop_back)
	shop_panel.add_child(back_btn)

func _update_display() -> void:
	gold_label.text = "Gold: %d" % Global.total_gold
	stats_label.text = "Best Level: %d | Total Kills: %d" % [Global.highest_level, Global.total_kills]

	# Update class selection
	var class_data = Global.classes[Global.selected_class]
	selected_class_label.text = "Current: %s - %s" % [class_data["name"], class_data["desc"]]

func _update_shop() -> void:
	var gold = shop_panel.get_node("ShopGold")
	gold.text = "Gold: %d" % Global.total_gold

	for i in shop_items.size():
		var item = shop_items[i]
		var btn = shop_buttons[i]
		var level = Global.get("meta_" + item["id"])
		var cost = Global.get_meta_cost(item["id"])

		btn.text = "%s (Lv.%d)\n%s\nCost: %d" % [item["name"], level, item["desc"], cost]
		btn.disabled = Global.total_gold < cost

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_class_pressed() -> void:
	_update_display()
	class_panel.visible = true

func _on_class_selected(class_id: String) -> void:
	Global.selected_class = class_id
	Global.save_game()
	_update_display()
	class_panel.visible = false

func _on_shop_pressed() -> void:
	_update_shop()
	shop_panel.visible = true

func _on_shop_buy(upgrade_id: String) -> void:
	if Global.buy_meta_upgrade(upgrade_id):
		_update_shop()
		_update_display()

func _on_shop_back() -> void:
	shop_panel.visible = false
	_update_display()
