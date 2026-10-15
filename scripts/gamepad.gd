extends RefCounted
const DEADZONE := 0.22

static func device_for(devices: Array, local_two: bool, second: bool) -> int:
	if devices.is_empty(): return -1
	if not local_two: return int(devices[0]) if not second else -1
	if devices.size() == 1: return int(devices[0]) if second else -1
	return int(devices[1 if second else 0])

static func direction(value: Vector2) -> Vector2:
	if value.length() <= DEADZONE: return Vector2.ZERO
	return value.normalized() * clampf((value.length() - DEADZONE) / (1.0 - DEADZONE), 0, 1)

static func decode(left: Vector2, right: Vector2, dpad: Vector2, buttons: int, trigger: float) -> Dictionary:
	var movement := direction(left)
	if dpad != Vector2.ZERO: movement = dpad.normalized()
	var aim := direction(right)
	if aim == Vector2.ZERO: aim = movement
	return {"x": movement.x, "aim": aim.normalized(), "bits": buttons | (4 if trigger > 0.5 else 0)}

static func sample(device: int) -> Dictionary:
	var left := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
	var right := Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
	var dpad := Vector2(float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)), float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)))
	var bits := 0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_A): bits |= 1
	if Input.is_joy_button_pressed(device, JOY_BUTTON_B) or Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER): bits |= 2
	if Input.is_joy_button_pressed(device, JOY_BUTTON_X): bits |= 4
	if Input.is_joy_button_pressed(device, JOY_BUTTON_Y): bits |= 8
	if Input.is_joy_button_pressed(device, JOY_BUTTON_RIGHT_SHOULDER): bits |= 16
	return decode(left, right, dpad, bits, Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT))

static func configure_menu() -> void:
	var bindings := {"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B, "ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT, "ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN}
	for action in bindings:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = bindings[action]
		if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		var event := InputEventJoypadMotion.new()
		event.device = -1
		event.axis = JOY_AXIS_LEFT_X if action in ["ui_left", "ui_right"] else JOY_AXIS_LEFT_Y
		event.axis_value = -1.0 if action in ["ui_left", "ui_up"] else 1.0
		if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)
