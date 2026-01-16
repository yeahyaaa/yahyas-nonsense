extends Control

func _ready():
	$PlayBtn.pressed.connect(_on_play)

func _on_play():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
