extends Control
class_name StageSelect
## StageSelect - Stage selection screen

@export var stage1_button: Button
@export var stage2_button: Button
@export var stage3_button: Button
@export var back_button: Button

# Track unlocked stages (saved in PlayerStats later)
var stages_completed: Array[int] = []

func _ready() -> void:
	_connect_buttons()
	_update_stage_buttons()

func _connect_buttons() -> void:
	if stage1_button:
		stage1_button.pressed.connect(_on_stage_selected.bind(1))
	if stage2_button:
		stage2_button.pressed.connect(_on_stage_selected.bind(2))
	if stage3_button:
		stage3_button.pressed.connect(_on_stage_selected.bind(3))
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _update_stage_buttons() -> void:
	# Stage 1 always available
	if stage1_button:
		stage1_button.disabled = false

	# Stage 2 requires completing stage 1
	if stage2_button:
		stage2_button.disabled = not (1 in stages_completed)

	# Stage 3 requires completing stage 2
	if stage3_button:
		stage3_button.disabled = not (2 in stages_completed)

func _on_stage_selected(stage: int) -> void:
	GameManager.current_stage = stage
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
