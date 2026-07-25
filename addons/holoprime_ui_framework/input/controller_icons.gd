### Handles the controller icons

extends Node

const BUILTIN_CONTROLLER_ICONS_DATA = preload("res://addons/holoprime_ui_framework/input/controller_icons_data.tres")

var controller_icons_data_override: ControllerIconsData


func get_input_method(event: InputEvent, player_index: int = 0) -> InputManager.InputMethod:
	return InputManager.get_input_method_for_event(event, player_index)


func get_icon(event: InputEvent, player_index: int = 0, debug_name := "") -> Texture2D:
	if event is InputEventKey and InputManager.use_keyboard_or_mouse_for(player_index):
		return _get_icon("keyboard", _get_key_name(event), debug_name)

	elif event is InputEventMouseButton and InputManager.use_keyboard_or_mouse_for(player_index):
		return _get_icon("mouse", "button_%s" % str(event.button_index), debug_name)

	elif event is InputEventScreenTouch and InputManager.use_touch_for(player_index):
		return _get_icon("touch", "touch" % event.action)
	elif event is InputEventMagnifyGesture and InputManager.use_touch_for(player_index):
		return _get_icon("touch", "gesture_magnify")
	elif event is InputEventPanGesture and InputManager.use_touch_for(player_index):
		return _get_icon("touch", "gesture_pan")
	elif event is InputEventAction and InputManager.use_touch_for(player_index):
		return _get_icon("touch", "action_%s" % event.action)

	elif event is InputEventJoypadButton and InputManager.use_gamepad_for(player_index):
		return _get_icon(InputManager.get_icon_prefix_for(player_index), _get_joy_button_name(event.button_index), debug_name)
	elif event is InputEventJoypadMotion and InputManager.use_gamepad_for(player_index):
		return _get_icon(InputManager.get_icon_prefix_for(player_index), _get_axis_name(event.axis), debug_name)

	elif event is InputEventAction:
		for sub_event: InputEvent in InputMap.action_get_events(event.action):
			var sprite := get_icon(sub_event, player_index, debug_name)
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


func _get_icon_from_data(icon_data: ControllerIconsData, prefix_fallback_chain: Array[String], action: String) -> Texture2D:
	if not icon_data:
		return null

	for fallback_prefix: String in prefix_fallback_chain:
		var icon: Texture2D = icon_data.icons.get(fallback_prefix, {}).get(action, null)
		if icon:
			return icon

	return null


func _get_icon(prefix: String, action: String, debug_name := "") -> Texture2D:
	if InputManager.has_dualsense_firefox_bug:
		match action:
			"1":
				action = "0"
			"2":
				action = "1"
			"0":
				action = "2"

	var prefix_fallback_chain := InputManager.get_prefix_fallback_chain(prefix)
	var icon := _get_icon_from_data(controller_icons_data_override, prefix_fallback_chain, action)

	if not icon:
		icon = _get_icon_from_data(BUILTIN_CONTROLLER_ICONS_DATA, prefix_fallback_chain, action)

	if not icon:
		Log.warn(&"ControllerIcons", "No icon found for %s:%s | %s" % [",".join(prefix_fallback_chain), action, debug_name])

	return icon
