extends Control
class_name CharacterCustomization
## CharacterCustomization - Full character builder with race, body, armor, colors

signal customization_changed(data: Dictionary)

@export var preview_sprite: Sprite2D
@export var class_selector: OptionButton
@export var race_selector: OptionButton
@export var body_selector: OptionButton
@export var hair_selector: OptionButton
@export var armor_selector: OptionButton
@export var skin_color_picker: ColorPickerButton
@export var hair_color_picker: ColorPickerButton
@export var primary_color_picker: ColorPickerButton
@export var secondary_color_picker: ColorPickerButton
@export var save_button: Button
@export var back_button: Button
@export var class_description: Label
@export var preview_container: Control

# Customization options
var races: Array[Dictionary] = [
	{"id": "human", "name": "Human", "unlocked": true},
	{"id": "elf", "name": "Elf", "unlocked": true},
	{"id": "dwarf", "name": "Dwarf", "unlocked": true},
	{"id": "orc", "name": "Orc", "unlocked": false},
	{"id": "undead", "name": "Undead", "unlocked": false}
]

var body_types: Array[Dictionary] = [
	{"id": "athletic", "name": "Athletic", "unlocked": true},
	{"id": "slim", "name": "Slim", "unlocked": true},
	{"id": "heavy", "name": "Heavy", "unlocked": true},
	{"id": "small", "name": "Halfling", "unlocked": false}
]

var hair_styles: Array[Dictionary] = [
	{"id": "short", "name": "Short", "unlocked": true},
	{"id": "long", "name": "Long", "unlocked": true},
	{"id": "bald", "name": "Bald", "unlocked": true},
	{"id": "mohawk", "name": "Mohawk", "unlocked": false},
	{"id": "ponytail", "name": "Ponytail", "unlocked": false},
	{"id": "braided", "name": "Braided", "unlocked": false}
]

var armor_sets: Array[Dictionary] = [
	{"id": "basic", "name": "Traveler's Garb", "unlocked": true},
	{"id": "leather", "name": "Leather Armor", "unlocked": true},
	{"id": "chainmail", "name": "Chainmail", "unlocked": false},
	{"id": "plate", "name": "Plate Armor", "unlocked": false},
	{"id": "robes", "name": "Mage Robes", "unlocked": false},
	{"id": "royal", "name": "Royal Regalia", "unlocked": false}
]

var current_customization: Dictionary

func _ready() -> void:
	current_customization = PlayerStats.character_customization.duplicate()
	_setup_selectors()
	_connect_signals()
	_update_preview()

func _setup_selectors() -> void:
	# Class selector
	if class_selector:
		class_selector.clear()
		for class_id in PlayerStats.unlocked_characters:
			var class_data = PlayerStats.classes.get(class_id, {})
			class_selector.add_item(class_data.get("name", class_id))
			class_selector.set_item_metadata(class_selector.item_count - 1, class_id)

		# Select current class
		for i in class_selector.item_count:
			if class_selector.get_item_metadata(i) == PlayerStats.selected_class:
				class_selector.select(i)
				break

	# Race selector
	if race_selector:
		_populate_selector(race_selector, races, current_customization["race"])

	# Body type selector
	if body_selector:
		_populate_selector(body_selector, body_types, current_customization["body_type"])

	# Hair selector
	if hair_selector:
		_populate_selector(hair_selector, hair_styles, current_customization["hair_style"])

	# Armor selector
	if armor_selector:
		_populate_selector(armor_selector, armor_sets, current_customization["armor_set"])

	# Color pickers
	if skin_color_picker:
		skin_color_picker.color = current_customization["skin_color"]
	if hair_color_picker:
		hair_color_picker.color = current_customization["hair_color"]
	if primary_color_picker:
		primary_color_picker.color = current_customization["primary_color"]
	if secondary_color_picker:
		secondary_color_picker.color = current_customization["secondary_color"]

func _populate_selector(selector: OptionButton, options: Array, current_value: String) -> void:
	selector.clear()
	var current_index = 0

	for i in options.size():
		var option = options[i]
		var display_name = option["name"]
		if not option["unlocked"]:
			display_name += " (Locked)"

		selector.add_item(display_name)
		selector.set_item_metadata(i, option["id"])
		selector.set_item_disabled(i, not option["unlocked"])

		if option["id"] == current_value:
			current_index = i

	selector.select(current_index)

func _connect_signals() -> void:
	if class_selector:
		class_selector.item_selected.connect(_on_class_changed)
	if race_selector:
		race_selector.item_selected.connect(_on_race_changed)
	if body_selector:
		body_selector.item_selected.connect(_on_body_changed)
	if hair_selector:
		hair_selector.item_selected.connect(_on_hair_changed)
	if armor_selector:
		armor_selector.item_selected.connect(_on_armor_changed)

	if skin_color_picker:
		skin_color_picker.color_changed.connect(_on_skin_color_changed)
	if hair_color_picker:
		hair_color_picker.color_changed.connect(_on_hair_color_changed)
	if primary_color_picker:
		primary_color_picker.color_changed.connect(_on_primary_color_changed)
	if secondary_color_picker:
		secondary_color_picker.color_changed.connect(_on_secondary_color_changed)

	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_class_changed(index: int) -> void:
	var class_id = class_selector.get_item_metadata(index)
	PlayerStats.selected_class = class_id
	_update_class_description()
	_update_preview()

func _on_race_changed(index: int) -> void:
	current_customization["race"] = race_selector.get_item_metadata(index)
	_update_preview()

func _on_body_changed(index: int) -> void:
	current_customization["body_type"] = body_selector.get_item_metadata(index)
	_update_preview()

func _on_hair_changed(index: int) -> void:
	current_customization["hair_style"] = hair_selector.get_item_metadata(index)
	_update_preview()

func _on_armor_changed(index: int) -> void:
	current_customization["armor_set"] = armor_selector.get_item_metadata(index)
	_update_preview()

func _on_skin_color_changed(color: Color) -> void:
	current_customization["skin_color"] = color
	_update_preview()

func _on_hair_color_changed(color: Color) -> void:
	current_customization["hair_color"] = color
	_update_preview()

func _on_primary_color_changed(color: Color) -> void:
	current_customization["primary_color"] = color
	_update_preview()

func _on_secondary_color_changed(color: Color) -> void:
	current_customization["secondary_color"] = color
	_update_preview()

func _update_class_description() -> void:
	if class_description:
		var class_data = PlayerStats.get_class_data()
		class_description.text = "%s\nStarting Weapon: %s\nPassive: %s" % [
			class_data["name"],
			class_data["starting_weapon"].replace("_", " ").capitalize(),
			class_data["description"]
		]

func _update_preview() -> void:
	if not preview_container:
		return

	# Clear existing preview
	for child in preview_container.get_children():
		if child != preview_sprite:
			child.queue_free()

	# Build character preview
	_draw_character_preview()

	customization_changed.emit(current_customization)

func _draw_character_preview() -> void:
	# This creates a simple visual representation of the character
	# In a full game, this would load actual sprites

	var body_scale = Vector2(1.0, 1.0)
	match current_customization["body_type"]:
		"slim": body_scale = Vector2(0.8, 1.1)
		"heavy": body_scale = Vector2(1.2, 0.95)
		"small": body_scale = Vector2(0.7, 0.7)

	# Body
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-15, -30) * body_scale,
		Vector2(15, -30) * body_scale,
		Vector2(18, 20) * body_scale,
		Vector2(-18, 20) * body_scale
	])
	body.color = current_customization["primary_color"]
	preview_container.add_child(body)

	# Head
	var head = Polygon2D.new()
	var head_points: PackedVector2Array = []
	for i in 16:
		var angle = i * TAU / 16
		head_points.append(Vector2.from_angle(angle) * 12 + Vector2(0, -45))
	head.polygon = head_points
	head.color = current_customization["skin_color"]
	preview_container.add_child(head)

	# Hair (if not bald)
	if current_customization["hair_style"] != "bald":
		var hair = Polygon2D.new()
		var hair_points: PackedVector2Array = []
		var hair_size = 14

		match current_customization["hair_style"]:
			"short":
				for i in 8:
					var angle = i * PI / 8 + PI
					hair_points.append(Vector2.from_angle(angle) * hair_size + Vector2(0, -48))
			"long":
				hair_points = PackedVector2Array([
					Vector2(-14, -55), Vector2(14, -55),
					Vector2(16, -35), Vector2(14, -20),
					Vector2(-14, -20), Vector2(-16, -35)
				])
			"mohawk":
				hair_points = PackedVector2Array([
					Vector2(-3, -60), Vector2(3, -60),
					Vector2(4, -45), Vector2(-4, -45)
				])

		hair.polygon = hair_points
		hair.color = current_customization["hair_color"]
		preview_container.add_child(hair)

	# Armor overlay
	var armor = Polygon2D.new()
	armor.polygon = PackedVector2Array([
		Vector2(-14, -25) * body_scale,
		Vector2(14, -25) * body_scale,
		Vector2(16, 5) * body_scale,
		Vector2(-16, 5) * body_scale
	])
	armor.color = current_customization["secondary_color"]
	preview_container.add_child(armor)

func _on_save_pressed() -> void:
	PlayerStats.character_customization = current_customization.duplicate()
	PlayerStats.save_data()
	_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
