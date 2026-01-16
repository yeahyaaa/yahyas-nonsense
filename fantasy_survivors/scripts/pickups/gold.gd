extends PickupBase
class_name GoldPickup
## GoldPickup - Currency for meta upgrades

@export var gold_value: int = 1

func _create_visual() -> void:
	# Coin shape
	var coin = Polygon2D.new()
	var radius = 5.0 + min(gold_value / 3.0, 4.0)

	var points: PackedVector2Array = []
	for i in 12:
		var angle = i * TAU / 12
		points.append(Vector2.from_angle(angle) * radius)
	coin.polygon = points
	coin.color = Color(1.0, 0.85, 0.2)
	add_child(coin)

	# Inner detail
	var inner = Polygon2D.new()
	var inner_points: PackedVector2Array = []
	for i in 12:
		var angle = i * TAU / 12
		inner_points.append(Vector2.from_angle(angle) * (radius * 0.6))
	inner.polygon = inner_points
	inner.color = Color(0.9, 0.7, 0.1)
	add_child(inner)

	# Collision
	var shape = CircleShape2D.new()
	shape.radius = radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

func collect(player: Node2D) -> void:
	PlayerStats.add_gold(gold_value)
	super.collect(player)
