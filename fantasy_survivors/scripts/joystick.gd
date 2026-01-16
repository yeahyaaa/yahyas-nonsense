extends Control
class_name VirtualJoystick

signal joystick_input(direction: Vector2)

@export var joystick_type: String = "move"
@export var dead_zone: float = 0.1
@export var max_distance: float = 60.0

var base: ColorRect
var knob: ColorRect
var is_pressed: bool = false
var touch_index: int = -1
var output: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Create base
	base = ColorRect.new()
	base.size = Vector2(140, 140)
	base.position = Vector2(30, 30)
	base.color = Color(0.2, 0.2, 0.25, 0.5)
	add_child(base)

	# Round the base with a shader or just use it as is
	# Create knob
	knob = ColorRect.new()
	knob.size = Vector2(60, 60)
	knob.position = base.position + (base.size - knob.size) / 2
	knob.color = Color(0.4, 0.4, 0.5, 0.8)
	add_child(knob)

	custom_minimum_size = Vector2(200, 200)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _is_in_area(event.position) and touch_index == -1:
			touch_index = event.index
			is_pressed = true
			_update_knob(event.position)
			modulate.a = 1.0
	else:
		if event.index == touch_index:
			_release()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_index and is_pressed:
		_update_knob(event.position)

func _is_in_area(pos: Vector2) -> bool:
	var rect = get_global_rect()
	return rect.has_point(pos)

func _update_knob(touch_pos: Vector2) -> void:
	var center = global_position + base.position + base.size / 2
	var diff = touch_pos - center

	if diff.length() > max_distance:
		diff = diff.normalized() * max_distance

	knob.position = base.position + (base.size - knob.size) / 2 + diff

	# Calculate output
	output = diff / max_distance
	if output.length() < dead_zone:
		output = Vector2.ZERO
	else:
		output = output.normalized() * ((output.length() - dead_zone) / (1.0 - dead_zone))

	joystick_input.emit(output)

func _release() -> void:
	is_pressed = false
	touch_index = -1
	output = Vector2.ZERO
	joystick_input.emit(output)

	# Return knob to center
	var tween = create_tween()
	tween.tween_property(knob, "position", base.position + (base.size - knob.size) / 2, 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.6, 0.2)

func get_output() -> Vector2:
	return output
