extends PickupBase
class_name XPGem
## XPGem - Dropped by enemies, gives XP when collected

@export var xp_value: int = 1

# Gem colors based on value
var gem_colors: Array[Color] = [
	Color(0.3, 0.8, 0.3),   # Green - 1 XP
	Color(0.3, 0.5, 0.9),   # Blue - 5 XP
	Color(0.7, 0.3, 0.9),   # Purple - 25 XP
	Color(1.0, 0.8, 0.2),   # Gold - 100 XP
]

func _create_visual() -> void:
	var gem = Polygon2D.new()

	# Diamond shape
	var size = 6.0 + min(xp_value / 5.0, 6.0)
	gem.polygon = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size * 0.6, 0),
		Vector2(0, size * 0.5),
		Vector2(-size * 0.6, 0)
	])

	# Color based on value
	var color_index = 0
	if xp_value >= 100:
		color_index = 3
	elif xp_value >= 25:
		color_index = 2
	elif xp_value >= 5:
		color_index = 1
	gem.color = gem_colors[color_index]

	add_child(gem)

	# Glow effect
	var glow = gem.duplicate()
	glow.scale = Vector2(1.4, 1.4)
	glow.color.a = 0.3
	glow.z_index = -1
	add_child(glow)

	# Collision
	var shape = CircleShape2D.new()
	shape.radius = size
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

func collect(player: Node2D) -> void:
	PlayerStats.add_xp(xp_value)
	super.collect(player)
