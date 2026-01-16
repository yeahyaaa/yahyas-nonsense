extends Area2D
class_name PickupBase
## PickupBase - Base class for all collectible items

@export var sprite: Sprite2D
@export var magnet_speed: float = 400.0
@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 3.0

var is_magnetized: bool = false
var target_player: Node2D
var initial_y: float
var time_alive: float = 0.0

func _ready() -> void:
	collision_layer = 32  # Pickups layer
	collision_mask = 0
	initial_y = position.y
	_create_visual()

func _physics_process(delta: float) -> void:
	time_alive += delta

	if is_magnetized and is_instance_valid(target_player):
		# Move towards player
		var direction = (target_player.global_position - global_position).normalized()
		position += direction * magnet_speed * delta

		# Speed up as it gets closer
		var distance = global_position.distance_to(target_player.global_position)
		if distance < 20:
			collect(target_player)
	else:
		# Idle bobbing animation
		position.y = initial_y + sin(time_alive * bob_speed) * bob_amplitude

func _create_visual() -> void:
	# Override in subclass
	pass

func magnetize(player: Node2D) -> void:
	is_magnetized = true
	target_player = player

func collect(player: Node2D) -> void:
	# Override in subclass
	_play_collect_effect()
	queue_free()

func _play_collect_effect() -> void:
	# Simple scale pop effect before being freed
	pass
