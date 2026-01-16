extends Control
class_name VirtualJoystick
## VirtualJoystick - Touch-based joystick for mobile controls

signal joystick_input(direction: Vector2)
signal joystick_released

@export var joystick_type: String = "move"  # "move" or "aim"
@export var dead_zone: float = 0.1
@export var max_distance: float = 64.0
@export var return_speed: float = 10.0
@export var always_visible: bool = false
@export var dynamic_position: bool = true  # Joystick appears at touch position

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var is_pressed: bool = false
var touch_index: int = -1
var center_position: Vector2
var current_output: Vector2 = Vector2.ZERO

func _ready() -> void:
	center_position = base.position + base.size / 2
	knob.position = base.size / 2 - knob.size / 2

	if not always_visible:
		modulate.a = 0.3

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _is_in_joystick_area(event.position) and touch_index == -1:
			touch_index = event.index
			is_pressed = true

			if dynamic_position:
				# Move joystick base to touch position
				var local_pos = event.position - global_position
				base.position = local_pos - base.size / 2
				center_position = event.position

			_update_knob_position(event.position)
			modulate.a = 1.0
	else:
		if event.index == touch_index:
			_release_joystick()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_index and is_pressed:
		_update_knob_position(event.position)

func _is_in_joystick_area(pos: Vector2) -> bool:
	# Check if touch is in this joystick's control area
	var rect = get_global_rect()
	return rect.has_point(pos)

func _update_knob_position(touch_pos: Vector2) -> void:
	var local_pos = touch_pos - center_position
	var distance = local_pos.length()

	if distance > max_distance:
		local_pos = local_pos.normalized() * max_distance

	# Update knob visual position
	var knob_center = base.size / 2 - knob.size / 2
	knob.position = knob_center + local_pos

	# Calculate output
	var output = local_pos / max_distance
	if output.length() < dead_zone:
		output = Vector2.ZERO
	else:
		# Remap to remove dead zone
		output = output.normalized() * ((output.length() - dead_zone) / (1.0 - dead_zone))

	current_output = output
	joystick_input.emit(output)

func _release_joystick() -> void:
	is_pressed = false
	touch_index = -1
	current_output = Vector2.ZERO
	joystick_released.emit()

	# Return knob to center
	var tween = create_tween()
	var knob_center = base.size / 2 - knob.size / 2
	tween.tween_property(knob, "position", knob_center, 0.1)

	if not always_visible:
		tween.parallel().tween_property(self, "modulate:a", 0.3, 0.2)

	if dynamic_position:
		# Reset base position
		tween.tween_property(base, "position", Vector2.ZERO, 0.1)
		center_position = base.position + base.size / 2

func get_output() -> Vector2:
	return current_output
