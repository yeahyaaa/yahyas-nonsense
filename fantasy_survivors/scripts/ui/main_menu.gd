extends Control
class_name MainMenu
## MainMenu - Title screen with navigation to game, customization, and shop

@export var play_button: Button
@export var customize_button: Button
@export var upgrades_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var gold_label: Label
@export var stats_container: VBoxContainer

func _ready() -> void:
	_connect_buttons()
	_update_display()

func _connect_buttons() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if customize_button:
		customize_button.pressed.connect(_on_customize_pressed)
	if upgrades_button:
		upgrades_button.pressed.connect(_on_upgrades_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _update_display() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % PlayerStats.total_gold

	if stats_container:
		_display_stats()

func _display_stats() -> void:
	for child in stats_container.get_children():
		child.queue_free()

	var stats = [
		"Highest Level: %d" % PlayerStats.highest_level,
		"Total Kills: %d" % PlayerStats.total_kills,
		"Characters: %d" % PlayerStats.unlocked_characters.size()
	]

	for stat in stats:
		var label = Label.new()
		label.text = stat
		label.add_theme_font_size_override("font_size", 18)
		stats_container.add_child(label)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")

func _on_customize_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_customization.tscn")

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/meta_shop.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
