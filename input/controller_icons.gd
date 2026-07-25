### Handles the controller icons

extends Node

const GAMEPAD_PREFIX := {
	InputManager.GamepadType.UNKNOWN: "xbox",
	InputManager.GamepadType.XBOX: "xbox",
	InputManager.GamepadType.PLAYSTATION: "playstation"
}

const FALLBACK_CONTROLLER_ICONS_DATA = preload("res://addons/holoprime_ui_framework/examples/controller_icons_data.tres")

var controller_icons_data_override: ControllerIconsData


func get_input_method(event: InputEvent) -> InputManager.InputMethod:
	if event is InputEventKey and InputManager.use_keyboard_or_mouse:
		return InputManager.InputMethod.KEYBOARD_AND_MOUSE

	elif event is InputEventMouseButton and InputManager.use_keyboard_or_mouse:
		return InputManager.InputMethod.KEYBOARD_AND_MOUSE

	elif event is InputEventScreenTouch and InputManager.use_touch:
		return InputManager.InputMethod.TOUCH
	elif event is InputEventMagnifyGesture and InputManager.use_touch:
		return InputManager.InputMethod.TOUCH
	elif event is InputEventPanGesture and InputManager.use_touch:
		return InputManager.InputMethod.TOUCH
	elif event is InputEventAction and InputManager.use_touch:
		return InputManager.InputMethod.TOUCH

	elif event is InputEventJoypadButton and InputManager.use_gamepad:
		return InputManager.InputMethod.GAMEPAD
	elif event is InputEventJoypadMotion and InputManager.use_gamepad:
		return InputManager.InputMethod.GAMEPAD

	elif event is InputEventAction:
		for sub_event: InputEvent in InputMap.action_get_events(event.action):
			var input_method := get_input_method(sub_event)
			if input_method != InputManager.InputMethod.UNKNOWN:
				return input_method

	return InputManager.InputMethod.UNKNOWN


func get_icon(event: InputEvent, debug_name := "") -> Texture2D:
	if event is InputEventKey and InputManager.use_keyboard_or_mouse:
		return _get_icon("keyboard", _get_key_name(event), debug_name)

	elif event is InputEventMouseButton and InputManager.use_keyboard_or_mouse:
		return _get_icon("mouse", "button_%s" % str(event.button_index), debug_name)

	elif event is InputEventScreenTouch and InputManager.use_touch:
		return _get_icon("touch", "touch" % event.action)
	elif event is InputEventMagnifyGesture and InputManager.use_touch:
		return _get_icon("touch", "gesture_magnify")
	elif event is InputEventPanGesture and InputManager.use_touch:
		return _get_icon("touch", "gesture_pan")
	elif event is InputEventAction and InputManager.use_touch:
		return _get_icon("touch", "action_%s" % event.action)

	elif event is InputEventJoypadButton and InputManager.use_gamepad:
		return _get_icon(GAMEPAD_PREFIX[InputManager.current_gamepad_type], _get_joy_button_name(event.button_index), debug_name)
	elif event is InputEventJoypadMotion and InputManager.use_gamepad:
		return _get_icon(GAMEPAD_PREFIX[InputManager.current_gamepad_type], _get_axis_name(event.axis), debug_name)

	elif event is InputEventAction:
		for sub_event: InputEvent in InputMap.action_get_events(event.action):
			var sprite := get_icon(sub_event, debug_name)
			if sprite:
				return sprite

	return null


func _get_joy_button_name(joy_button: JoyButton) -> String:
	return "button_%s" % str(joy_button)


func _get_axis_name(axis: JoyAxis) -> String:
	return "axis_%s" % str(axis)


func _get_key_name(event: InputEventKey) -> String:
	if event.physical_keycode != KEY_NONE:
		return event.as_text_physical_keycode().to_lower()
	else:
		return event.as_text_keycode().to_lower()


func _get_icon(prefix: String, action: String, debug_name := "") -> Texture2D:
	if InputManager.has_dualsense_firefox_bug:
		match action:
			"1":
				action = "0"
			"2":
				action = "1"
			"0":
				action = "2"

	var icon: Texture2D

	if controller_icons_data_override:
		icon = controller_icons_data_override.icons.get(prefix, {}).get(action, null)

	if not icon:
		icon = FALLBACK_CONTROLLER_ICONS_DATA.icons.get(prefix, {}).get(action, null)

	if not icon:
		Log.warn(&"ControllerIcons", "No icon found for %s:%s | %s" % [prefix, action, debug_name])

	return icon
