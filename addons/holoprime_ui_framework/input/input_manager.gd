extends Node

### Handles the input methots in the game

signal warped_mouse(canvas_positon: Vector2)
signal input_method_changed(new_input_method: InputMethod)

const TOUCH_POSITION_ADJUSTMENT := Vector2.UP * 16

enum InputMethod { UNKNOWN, KEYBOARD_AND_MOUSE, TOUCH, GAMEPAD }

enum KeyboardMouseMode { UNKNOWN, KEYBOARD, MOUSE }

enum GamepadType { UNKNOWN, XBOX, PLAYSTATION }

const GAMEPAD_SUBSTRINGS := {
	GamepadType.XBOX: ["Xbox"],
	GamepadType.PLAYSTATION: ["PS5 Controller", "DualSense"]
}

#region Public properties

var current_input_method: InputMethod:
	get:
		return _current_input_method

var current_keyboard_mouse_mode: KeyboardMouseMode:
	get:
		return _current_keyboard_mouse_mode

var current_gamepad_type: GamepadType:
	get:
		return _current_gamepad_type

var current_gamepad_name: String:
	get:
		return _current_gamepad_name

var use_keyboard_or_mouse: bool:
	get:
		return _current_input_method == InputMethod.KEYBOARD_AND_MOUSE

var use_mouse: bool:
	get:
		return use_keyboard_or_mouse and _current_keyboard_mouse_mode == KeyboardMouseMode.MOUSE

var use_keyboard: bool:
	get:
		return use_keyboard_or_mouse and _current_keyboard_mouse_mode == KeyboardMouseMode.KEYBOARD

var use_touch: bool:
	get:
		return _current_input_method == InputMethod.TOUCH

var use_gamepad: bool:
	get:
		return _current_input_method == InputMethod.GAMEPAD

var forced_input_method := InputMethod.UNKNOWN:
	set(value):
		Log.info(&"InputManager", "Forcing input method: %s" % InputMethod.keys()[value])
		forced_input_method = value
		_set_input_method(value)
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if value != InputMethod.TOUCH else Input.MOUSE_MODE_VISIBLE

var force_mouse: bool:
	get:
		return forced_input_method == InputMethod.KEYBOARD_AND_MOUSE

var force_touch: bool:
	get:
		return forced_input_method == InputMethod.TOUCH

var force_gamepad: bool:
	get:
		return forced_input_method == InputMethod.GAMEPAD

var is_dragging := false

var has_dualsense_firefox_bug := false

#endregion

#region Private fields

var _current_input_method := InputMethod.UNKNOWN

var _new_input_method := InputMethod.UNKNOWN

var _current_keyboard_mouse_mode := KeyboardMouseMode.UNKNOWN

var _new_keyboard_mouse_mode := KeyboardMouseMode.UNKNOWN

var _current_gamepad_type := GamepadType.UNKNOWN

var _current_gamepad_name := ""

var _new_gamepad_name := ""

var _warping_mouse_to: Array[Vector2] = []

#endregion

#region Lifecycle methods

func _enter_tree() -> void:
	var connected_joypads := Input.get_connected_joypads()

	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		_set_input_method(InputMethod.TOUCH)
	elif Input.get_connected_joypads().size() > 0:
		_set_input_method(InputMethod.GAMEPAD, Input.get_joy_name(connected_joypads[0]))
	elif DisplayServer.keyboard_get_layout_count() > 0:
		_set_input_method(InputMethod.KEYBOARD_AND_MOUSE)


func _ready() -> void:
	set_process_input(true)


func _process(_delta: float) -> void:
	if _new_input_method != InputMethod.UNKNOWN:
		_set_input_method_late.call_deferred()


func _input(event: InputEvent) -> void:
	if forced_input_method != InputMethod.UNKNOWN:
		return

	if event is InputEventMouse and event.position in _warping_mouse_to:
		# Event from warping the mouse, so ignore
		_warping_mouse_to.remove_at(_warping_mouse_to.find(event.position))
		return

	if ignore_event(event):
		return

	if event is InputEventKey:
		_set_input_method(InputMethod.KEYBOARD_AND_MOUSE, "", KeyboardMouseMode.KEYBOARD)
	elif event is InputEventMouse and not use_touch:
		_set_input_method(InputMethod.KEYBOARD_AND_MOUSE, "", KeyboardMouseMode.MOUSE)
	elif event is InputEventScreenTouch or event is InputEventGesture:
		_set_input_method(InputMethod.TOUCH)
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if OS.has_feature("web"):
			_set_input_method(InputMethod.GAMEPAD, JavaScriptBridge.eval("navigator.getGamepads()[%d].id" % event.device))
		else:
			_set_input_method(InputMethod.GAMEPAD, Input.get_joy_name(event.device))

#endregion

#region Public methods

func adjust_for_touch(pos: Vector2) -> Vector2:
	return pos + TOUCH_POSITION_ADJUSTMENT if use_touch and is_dragging else pos


func ignore_event(event: InputEvent) -> bool:
	if event is InputEventMouseMotion and event.relative.is_zero_approx():
		return true
	elif event is InputEventMouseMotion and (force_gamepad or force_touch) and not is_dragging:
		return true
	elif event is InputEventJoypadMotion and event.axis_value < 0.25:
		return true
	else:
		return false


func warp_mouse(canvas_position: Vector2) -> void:
	_warping_mouse_to.append(canvas_position)
	get_viewport().warp_mouse(canvas_position)
	warped_mouse.emit(canvas_position)

#endregion

#region Private methods

func _set_input_method(input_method: InputMethod, gamepad_name := "", keyboard_mouse_mode := KeyboardMouseMode.UNKNOWN) -> void:
	_new_input_method = input_method
	_new_gamepad_name = gamepad_name
	_new_keyboard_mouse_mode = keyboard_mouse_mode


func _set_input_method_late() -> void:
	var any_changed := false

	if _current_input_method != _new_input_method:
		Log.debug(&"InputManager", "_current_input_method %s => %s" % [InputMethod.keys()[_current_input_method], InputMethod.keys()[_new_input_method]])
		_current_input_method = _new_input_method
		any_changed = true

	if _current_gamepad_name != _new_gamepad_name:
		Log.debug(&"InputManager", "Current gamepad name:  %s => %s" % [_current_gamepad_name, _new_gamepad_name])
		_current_gamepad_name = _new_gamepad_name

		var new_gamepad_type := _get_gamepad_type(_new_gamepad_name)
		if _current_gamepad_type != new_gamepad_type:
			Log.debug(&"InputManager", "Current gamepad type:  %s => %s (%s)" % [GamepadType.keys()[_current_gamepad_type], GamepadType.keys()[new_gamepad_type], _new_gamepad_name])
			_current_gamepad_type = new_gamepad_type
			any_changed = true

	if _current_keyboard_mouse_mode != _new_keyboard_mouse_mode:
		Log.debug(&"InputManager", "_current_keyboard_mouse_mode %s => %s" % [KeyboardMouseMode.keys()[_current_keyboard_mouse_mode], KeyboardMouseMode.keys()[_new_keyboard_mouse_mode]])
		_current_keyboard_mouse_mode = _new_keyboard_mouse_mode
		any_changed = true

	if any_changed:
		input_method_changed.emit(_current_input_method)

		# Fix firefox bugs with dualsense controller
		var is_firefox: bool = OS.has_feature("web") and JavaScriptBridge.eval("navigator.userAgent.includes('Firefox')")
		has_dualsense_firefox_bug = is_firefox and _current_gamepad_name == "054c-0ce6-DualSense Wireless Controller"

		if is_firefox:
			InputMap.load_from_project_settings()
			if has_dualsense_firefox_bug:
				for action in InputMap.get_actions():
					for event in InputMap.action_get_events(action):
						if event is InputEventJoypadButton:
							match event.button_index:
								JOY_BUTTON_A:
									event.button_index = JOY_BUTTON_B
								JOY_BUTTON_B:
									event.button_index = JOY_BUTTON_X
								JOY_BUTTON_X:
									event.button_index = JOY_BUTTON_A

	_new_input_method = InputMethod.UNKNOWN
	_new_gamepad_name = ""
	_new_keyboard_mouse_mode = KeyboardMouseMode.UNKNOWN


func _get_gamepad_type(gamepad_name: String) -> GamepadType:
	for key: GamepadType in GAMEPAD_SUBSTRINGS.keys():
		if GAMEPAD_SUBSTRINGS[key].any(func(i: String) -> bool: return gamepad_name.to_lower().contains(i.to_lower())):
			return key

	return GamepadType.UNKNOWN

#endregion
