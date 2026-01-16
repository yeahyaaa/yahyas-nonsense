extends Node
## SaveManager - Handles saving and loading game data

const SAVE_PATH = "user://fantasy_survivors_save.json"

func save_player_data(player_stats: Node) -> void:
	var save_data = {
		"total_gold": player_stats.total_gold,
		"highest_level": player_stats.highest_level,
		"total_kills": player_stats.total_kills,
		"unlocked_characters": player_stats.unlocked_characters,
		"unlocked_cosmetics": player_stats.unlocked_cosmetics,
		"meta_upgrades": player_stats.meta_upgrades,
		"selected_class": player_stats.selected_class,
		"character_customization": _serialize_customization(player_stats.character_customization)
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func load_player_data(player_stats: Node) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.get_data()
			_apply_save_data(player_stats, data)

func _apply_save_data(player_stats: Node, data: Dictionary) -> void:
	if "total_gold" in data:
		player_stats.total_gold = data["total_gold"]
	if "highest_level" in data:
		player_stats.highest_level = data["highest_level"]
	if "total_kills" in data:
		player_stats.total_kills = data["total_kills"]
	if "unlocked_characters" in data:
		player_stats.unlocked_characters = Array(data["unlocked_characters"], TYPE_STRING, "", null)
	if "unlocked_cosmetics" in data:
		player_stats.unlocked_cosmetics = data["unlocked_cosmetics"]
	if "meta_upgrades" in data:
		for key in data["meta_upgrades"]:
			if key in player_stats.meta_upgrades:
				player_stats.meta_upgrades[key] = data["meta_upgrades"][key]
	if "selected_class" in data:
		player_stats.selected_class = data["selected_class"]
	if "character_customization" in data:
		player_stats.character_customization = _deserialize_customization(data["character_customization"])

func _serialize_customization(customization: Dictionary) -> Dictionary:
	var serialized = customization.duplicate()
	for key in serialized:
		if serialized[key] is Color:
			var c = serialized[key]
			serialized[key] = {"r": c.r, "g": c.g, "b": c.b, "a": c.a}
	return serialized

func _deserialize_customization(data: Dictionary) -> Dictionary:
	var deserialized = data.duplicate()
	var color_keys = ["skin_color", "hair_color", "primary_color", "secondary_color"]
	for key in color_keys:
		if key in deserialized and deserialized[key] is Dictionary:
			var c = deserialized[key]
			deserialized[key] = Color(c["r"], c["g"], c["b"], c.get("a", 1.0))
	return deserialized

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
