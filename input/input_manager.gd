extends Node

### Handles the input methots in the game

signal warped_mouse(canvas_positon: Vector2)
signal input_method_changed(new_input_method: InputMethod, player_index: int)

const TOUCH_POSITION_ADJUSTMENT := Vector2.UP * 16

enum InputMethod { UNKNOWN, KEYBOARD_AND_MOUSE, TOUCH, GAMEPAD }

enum KeyboardMouseMode { UNKNOWN, KEYBOARD, MOUSE }

enum GamepadType { UNKNOWN, XBOX, PLAYSTATION }

const CONTROLLER_DETECTION_CONFIG_PATH := "res://addons/holoprime_ui_framework/input/controller_detection_config.tres"

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

var current_gamepad_device: int:
	get:
		return _current_gamepad_device

var current_gamepad_icon_prefix: String:
	get:
		return _current_gamepad_icon_prefix

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

var _current_gamepad_device := -1

var _new_gamepad_device := -1

var _current_gamepad_detection_string := ""

var _new_gamepad_detection_string := ""

var _current_gamepad_icon_prefix := "xbox"

var _cached_controller_detection_config: ControllerDetectionConfig

var _warping_mouse_to: Array[Vector2] = []

#endregion

#region Lifecycle methods

func _enter_tree() -> void:
	var connected_joypads := Input.get_connected_joypads()

	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		_set_input_method(InputMethod.TOUCH)
	elif connected_joypads.size() > 0:
		_set_gamepad_input_method(connected_joypads[0])
	elif DisplayServer.keyboard_get_layout_count() > 0:
		_set_input_method(InputMethod.KEYBOARD_AND_MOUSE)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	MultiplayerInput.player_input_changed.connect(_on_player_input_changed)


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
		_set_gamepad_input_method(event.device)

#endregion

#region Public methods

func adjust_for_touch(pos: Vector2) -> Vector2:
	return pos + TOUCH_POSITION_ADJUSTMENT if use_touch and is_dragging else pos


func get_input_method_for_event(event: InputEvent, player_index: int = 0) -> InputMethod:
	if event is InputEventKey and use_keyboard_or_mouse_for(player_index):
		return InputMethod.KEYBOARD_AND_MOUSE

	elif event is InputEventMouseButton and use_keyboard_or_mouse_for(player_index):
		return InputMethod.KEYBOARD_AND_MOUSE

	elif event is InputEventScreenTouch and use_touch_for(player_index):
		return InputMethod.TOUCH
	elif event is InputEventMagnifyGesture and use_touch_for(player_index):
		return InputMethod.TOUCH
	elif event is InputEventPanGesture and use_touch_for(player_index):
		return InputMethod.TOUCH
	elif event is InputEventAction and use_touch_for(player_index):
		return InputMethod.TOUCH

	elif event is InputEventJoypadButton and use_gamepad_for(player_index):
		return InputMethod.GAMEPAD
	elif event is InputEventJoypadMotion and use_gamepad_for(player_index):
		return InputMethod.GAMEPAD

	elif event is InputEventAction:
		for sub_event: InputEvent in InputMap.action_get_events(event.action):
			var input_method := get_input_method_for_event(sub_event, player_index)
			if input_method != InputMethod.UNKNOWN:
				return input_method

	return InputMethod.UNKNOWN


func ignore_event(event: InputEvent) -> bool:
	if event is InputEventMouseMotion and event.relative.is_zero_approx():
		return true
	elif event is InputEventMouseMotion and (force_gamepad or force_touch) and not is_dragging:
		return true
	elif event is InputEventJoypadMotion and absf(event.axis_value) < 0.2:
		return true
	else:
		return false


func warp_mouse(canvas_position: Vector2) -> void:
	_warping_mouse_to.append(canvas_position)
	get_viewport().warp_mouse(canvas_position)
	warped_mouse.emit(canvas_position)


func get_prefix_fallback_chain(prefix := _current_gamepad_icon_prefix) -> Array[String]:
	return _get_prefix_fallback_chain(prefix)


func get_input_method_for(player_index: int) -> InputMethod:
	var input := MultiplayerInput.get_player_input(player_index)
	if input == null:
		# AUTO indices follow global state; explicit slots 1+ are NONE when unpinned.
		return _current_input_method if _is_auto_index(player_index) else InputMethod.UNKNOWN
	return input.input_method


func get_gamepad_type_for(player_index: int) -> GamepadType:
	var input := MultiplayerInput.get_player_input(player_index)
	if input == null:
		return _current_gamepad_type if _is_auto_index(player_index) else GamepadType.UNKNOWN
	if input.input_method != InputMethod.GAMEPAD:
		return GamepadType.UNKNOWN
	return _get_gamepad_type(_get_gamepad_detection_string(input.gamepad_id, _get_gamepad_name(input.gamepad_id)))


func get_icon_prefix_for(player_index: int) -> String:
	var input := MultiplayerInput.get_player_input(player_index)
	if input == null:
		return _current_gamepad_icon_prefix if _is_auto_index(player_index) else "keyboard"
	if input.input_method != InputMethod.GAMEPAD:
		return "keyboard"
	return _get_gamepad_icon_prefix(_get_gamepad_detection_string(input.gamepad_id, _get_gamepad_name(input.gamepad_id)))


func use_gamepad_for(player_index: int) -> bool:
	return get_input_method_for(player_index) == InputMethod.GAMEPAD


func use_keyboard_or_mouse_for(player_index: int) -> bool:
	return get_input_method_for(player_index) == InputMethod.KEYBOARD_AND_MOUSE


func use_touch_for(player_index: int) -> bool:
	return get_input_method_for(player_index) == InputMethod.TOUCH

#endregion

#region Private methods

func _set_input_method(input_method: InputMethod, gamepad_name := "", keyboard_mouse_mode := KeyboardMouseMode.UNKNOWN, gamepad_detection_string := "", gamepad_device := -1) -> void:
	_new_input_method = input_method
	_new_gamepad_name = gamepad_name
	_new_gamepad_detection_string = gamepad_detection_string
	_new_keyboard_mouse_mode = keyboard_mouse_mode
	_new_gamepad_device = gamepad_device


func _set_input_method_late() -> void:
	var any_changed := false

	if _current_input_method != _new_input_method:
		Log.debug(&"InputManager", "_current_input_method %s => %s" % [InputMethod.keys()[_current_input_method], InputMethod.keys()[_new_input_method]])
		_current_input_method = _new_input_method
		any_changed = true

	if _current_gamepad_name != _new_gamepad_name:
		Log.debug(&"InputManager", "Current gamepad name:  %s => %s" % [_current_gamepad_name, _new_gamepad_name])
		_current_gamepad_name = _new_gamepad_name

	if _current_gamepad_device != _new_gamepad_device:
		Log.debug(&"InputManager", "Current gamepad device:  %s => %s" % [_current_gamepad_device, _new_gamepad_device])
		_current_gamepad_device = _new_gamepad_device

	if _current_gamepad_detection_string != _new_gamepad_detection_string:
		Log.debug(&"InputManager", "Current gamepad detection string:  %s => %s" % [_current_gamepad_detection_string, _new_gamepad_detection_string])
		_current_gamepad_detection_string = _new_gamepad_detection_string

		var new_gamepad_prefix := _get_gamepad_icon_prefix(_new_gamepad_detection_string)
		if _current_gamepad_icon_prefix != new_gamepad_prefix:
			Log.debug(&"InputManager", "Current gamepad icon prefix:  %s => %s (%s)" % [_current_gamepad_icon_prefix, new_gamepad_prefix, _new_gamepad_detection_string])
			_current_gamepad_icon_prefix = new_gamepad_prefix
			any_changed = true

		var new_gamepad_type := _get_gamepad_type(_new_gamepad_detection_string)
		if _current_gamepad_type != new_gamepad_type:
			Log.debug(&"InputManager", "Current gamepad type:  %s => %s (%s)" % [GamepadType.keys()[_current_gamepad_type], GamepadType.keys()[new_gamepad_type], _new_gamepad_detection_string])
			_current_gamepad_type = new_gamepad_type
			any_changed = true

	if _current_keyboard_mouse_mode != _new_keyboard_mouse_mode:
		Log.debug(&"InputManager", "_current_keyboard_mouse_mode %s => %s" % [KeyboardMouseMode.keys()[_current_keyboard_mouse_mode], KeyboardMouseMode.keys()[_new_keyboard_mouse_mode]])
		_current_keyboard_mouse_mode = _new_keyboard_mouse_mode
		any_changed = true

	if any_changed:
		# Global device changes target AUTO/no-context consumers, not pinned slots.
		input_method_changed.emit(_current_input_method, MultiplayerContext.AUTO_PLAYER_INDEX)

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
	_new_gamepad_device = -1
	_new_gamepad_detection_string = ""
	_new_keyboard_mouse_mode = KeyboardMouseMode.UNKNOWN


func _set_gamepad_input_method(device: int) -> void:
	var gamepad_name := _get_gamepad_name(device)
	var detection_string := _get_gamepad_detection_string(device, gamepad_name)
	_set_input_method(InputMethod.GAMEPAD, gamepad_name, KeyboardMouseMode.UNKNOWN, detection_string, device)


func _get_gamepad_name(device: int) -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("var gp = navigator.getGamepads()[%d]; gp ? gp.id : '';" % device))

	return Input.get_joy_name(device)


func _get_gamepad_detection_string(device: int, gamepad_name: String) -> String:
	var normalized_name := gamepad_name.strip_edges().to_lower()
	var guid := Input.get_joy_guid(device).strip_edges().to_lower()
	if guid == "":
		return normalized_name

	return "%s %s" % [normalized_name, guid]


func _get_gamepad_type(gamepad_detection_string: String) -> GamepadType:
	var matched_prefix := _get_matching_prefix(gamepad_detection_string)
	if matched_prefix == "":
		return GamepadType.UNKNOWN

	var config := _get_controller_detection_config()
	for fallback_prefix: String in _get_prefix_fallback_chain(matched_prefix):
		var gamepad_type_name := _get_gamepad_type_name_by_prefix(config, fallback_prefix)
		if gamepad_type_name == "":
			continue

		var gamepad_type_idx := GamepadType.keys().find(gamepad_type_name)
		if gamepad_type_idx != -1:
			return gamepad_type_idx

		Log.warn(&"InputManager", "Unknown gamepad type in controller detection config: %s" % gamepad_type_name)
		return GamepadType.UNKNOWN

	return GamepadType.UNKNOWN


func _get_gamepad_icon_prefix(gamepad_detection_string: String) -> String:
	var matched_prefix := _get_matching_prefix(gamepad_detection_string)
	if matched_prefix != "":
		return matched_prefix

	var config := _get_controller_detection_config()
	return String(config.gamepad_type_prefixes.get("UNKNOWN", "xbox"))


func _get_matching_prefix(gamepad_detection_string: String) -> String:
	var config := _get_controller_detection_config()
	var normalized_detection_string := gamepad_detection_string.to_lower()
	for prefix: String in config.controller_match_order:
		var substrings := config.controller_match_substrings.get(prefix, PackedStringArray()) as PackedStringArray
		if _contains_any(normalized_detection_string, substrings):
			return prefix

	return ""


func _get_prefix_fallback_chain(prefix: String) -> Array[String]:
	var config := _get_controller_detection_config()
	var fallback_chain: Array[String] = []
	var visited := {}
	var current_prefix := prefix

	while current_prefix != "" and not visited.has(current_prefix):
		fallback_chain.append(current_prefix)
		visited[current_prefix] = true
		current_prefix = config.controller_fallbacks.get(current_prefix, "")

	return fallback_chain


func _get_gamepad_type_name_by_prefix(config: ControllerDetectionConfig, prefix: String) -> String:
	for gamepad_type_name: String in config.gamepad_type_prefixes.keys():
		if gamepad_type_name == "UNKNOWN":
			continue
		if String(config.gamepad_type_prefixes.get(gamepad_type_name, "")).to_lower() == prefix.to_lower():
			return gamepad_type_name.to_upper()

	return ""


func _contains_any(text: String, substrings: PackedStringArray) -> bool:
	for substring: String in substrings:
		if text.contains(substring.to_lower()):
			return true

	return false


## True for AUTO indices that follow the global last-used device: the no-context sentinel
## (-1) and the legacy single-player default (player 0) when it has no explicit pin.
func _is_auto_index(player_index: int) -> bool:
	return player_index <= 0


func _on_player_input_changed(player_index: int) -> void:
	input_method_changed.emit(get_input_method_for(player_index), player_index)


func _get_controller_detection_config() -> ControllerDetectionConfig:
	if _cached_controller_detection_config:
		return _cached_controller_detection_config

	_cached_controller_detection_config = load(CONTROLLER_DETECTION_CONFIG_PATH) as ControllerDetectionConfig
	if _cached_controller_detection_config:
		return _cached_controller_detection_config

	Log.warn(&"InputManager", "Could not load controller detection config: %s. Using empty config." % CONTROLLER_DETECTION_CONFIG_PATH)
	_cached_controller_detection_config = ControllerDetectionConfig.new()
	return _cached_controller_detection_config

#endregion
