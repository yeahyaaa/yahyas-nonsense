extends Area2D
class_name ProjectileBase
## ProjectileBase - Base class for weapon projectiles

@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: float = 10.0
var pierce: int = 1
var knockback: float = 50.0
var area_scale: float = 1.0
var lifetime: float = 5.0
var enemies_hit: Array[Node] = []

var crit_multiplier: float = 1.0
var is_critical: bool = false

func _ready() -> void:
	collision_layer = 4  # Player projectiles
	collision_mask = 2   # Enemies

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Apply area scale
	if collision_shape:
		scale *= area_scale

	# Check for critical hit
	var crit_chance = PlayerStats.get_stat("crit_chance")
	if randf() < crit_chance:
		is_critical = true
		crit_multiplier = PlayerStats.get_stat("crit_damage")
		_apply_crit_visual()

	# Rotate to face direction
	rotation = direction.angle()

	# Start lifetime timer
	await get_tree().create_timer(lifetime).timeout
	_destroy()

func _physics_process(delta: float) -> void:
	_move(delta)

func _move(delta: float) -> void:
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area.get_parent())

func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _try_hit(target: Node) -> void:
	if target in enemies_hit:
		return

	if target.has_method("take_damage"):
		var final_damage = damage * crit_multiplier
		target.take_damage(final_damage, self)
		_apply_knockback(target)
		enemies_hit.append(target)

		if is_critical:
			_spawn_crit_effect()

		pierce -= 1
		if pierce <= 0:
			_destroy()

func _apply_knockback(target: Node) -> void:
	if target.has_method("apply_knockback"):
		target.apply_knockback(direction * knockback)

func _apply_crit_visual() -> void:
	if sprite:
		sprite.modulate = Color(1.2, 0.8, 0.3)  # Golden glow for crits
		scale *= 1.2

func _spawn_crit_effect() -> void:
	# Override in subclass for specific crit effects
	pass

func _destroy() -> void:
	queue_free()
