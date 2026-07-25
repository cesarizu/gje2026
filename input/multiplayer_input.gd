extends Node

## An explicit input assignment for a player.
##
## input_method is always KEYBOARD_AND_MOUSE or GAMEPAD (the states a player can be pinned
## to). gamepad_id is only meaningful when input_method == GAMEPAD.
class PlayerInput:
	var input_method: InputManager.InputMethod
	var gamepad_id: int = -1

	func _init(method: InputManager.InputMethod, gamepad := -1) -> void:
		input_method = method
		gamepad_id = gamepad


## Maps player index (0, 1, ...) to an explicit input assignment.
##
## Absence from this map is meaningful: an unassigned player 0 is AUTO (follows the global
## last-used device, like single-player) while an unassigned player 1+ is NONE (no input).
## Only the pinned states (keyboard, a specific joypad) are stored here.
##
## Keyboard assignments carry no device id because Godot collapses all keyboards/mice into a
## single logical device (see godot-proposals#7161), so the keyboard is one exclusive slot.
var _player_inputs: Dictionary[int, PlayerInput] = {}

signal player_input_changed(player_index: int)


## Pin a player to the keyboard. Exclusive: removed from any other player first, with a warning.
func set_player_keyboard(player_index: int) -> void:
	_evict_matching(player_index, InputManager.InputMethod.KEYBOARD_AND_MOUSE, -1)
	_player_inputs[player_index] = PlayerInput.new(InputManager.InputMethod.KEYBOARD_AND_MOUSE)
	player_input_changed.emit(player_index)


## Pin a player to a specific joypad. Exclusive: remapped from any other holder, with a warning.
func set_player_gamepad(player_index: int, gamepad_id: int) -> void:
	_evict_matching(player_index, InputManager.InputMethod.GAMEPAD, gamepad_id)
	_player_inputs[player_index] = PlayerInput.new(InputManager.InputMethod.GAMEPAD, gamepad_id)
	player_input_changed.emit(player_index)


## Clear a player's assignment (back to AUTO for player 0, NONE for others).
func unset_player_input(player_index: int) -> void:
	if not _player_inputs.has(player_index):
		return
	_player_inputs.erase(player_index)
	player_input_changed.emit(player_index)


## Returns the explicit assignment for a player, or null when AUTO (player 0) or NONE (others).
func get_player_input(player_index: int) -> PlayerInput:
	return _player_inputs.get(player_index)


func reset() -> void:
	var changed_player_indexes := _player_inputs.keys()
	_player_inputs.clear()

	if not changed_player_indexes.has(0):
		changed_player_indexes.append(0)

	for player_index: int in changed_player_indexes:
		player_input_changed.emit(player_index)


## Returns true if the action is active for the given player's assigned device.
func is_action_pressed(action: StringName, player_index: int) -> bool:
	var input := get_player_input(player_index)
	if input == null:
		return Input.is_action_pressed(action) if _is_auto(player_index) else false
	if input.input_method == InputManager.InputMethod.GAMEPAD:
		return _is_joypad_action_active(action, input.gamepad_id)
	return Input.is_action_pressed(action)


## Returns a [-1, 1] axis value for the given player's assigned device.
func get_axis(negative_action: StringName, positive_action: StringName, player_index: int) -> float:
	var input := get_player_input(player_index)
	if input == null:
		return Input.get_axis(negative_action, positive_action) if _is_auto(player_index) else 0.0
	if input.input_method == InputManager.InputMethod.GAMEPAD:
		return _get_joypad_axis(negative_action, positive_action, input.gamepad_id)
	return Input.get_axis(negative_action, positive_action)


## Returns true if the given event belongs to the device assigned to player_index.
func is_event_for_player(event: InputEvent, player_index: int) -> bool:
	var input := get_player_input(player_index)
	if input == null:
		return _is_auto(player_index)
	if input.input_method == InputManager.InputMethod.GAMEPAD:
		return (event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.device == input.gamepad_id
	return event is InputEventKey or event is InputEventMouse


## Returns the gamepad device id assigned to the player, or -1 when the player is not on a
## gamepad. Useful for routing per-player rumble through Input.start_joy_vibration().
func get_player_gamepad_id(player_index: int) -> int:
	var input := get_player_input(player_index)
	if input == null:
		# AUTO players follow the global last-used device; fall back to gamepad 0.
		return 0 if _is_auto(player_index) else -1
	return input.gamepad_id if input.input_method == InputManager.InputMethod.GAMEPAD else -1


## True when the player has no explicit assignment but should follow the global last-used
## device: the no-context AUTO sentinel (-1) and player 0 (legacy single-player default).
func _is_auto(player_index: int) -> bool:
	return player_index <= 0 and not _player_inputs.has(player_index)


## Removes any other player currently assigned to the same source, logging a warning.
func _evict_matching(player_index: int, input_method: InputManager.InputMethod, gamepad_id: int) -> void:
	var previous_index := -1
	for other_index: int in _player_inputs:
		if other_index == player_index:
			continue
		var other := _player_inputs[other_index]
		if other.input_method == input_method and (input_method != InputManager.InputMethod.GAMEPAD or other.gamepad_id == gamepad_id):
			previous_index = other_index
			break

	if previous_index != -1:
		Log.warn(&"MultiplayerInput", "Input was assigned to player %d, remapping to player %d" % [previous_index, player_index])
		_player_inputs.erase(previous_index)
		player_input_changed.emit(previous_index)


func _is_joypad_action_active(action: StringName, device_id: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			if Input.is_joy_button_pressed(device_id, event.button_index):
				return true
		elif event is InputEventJoypadMotion:
			var axis_value := Input.get_joy_axis(device_id, event.axis)
			if event.axis_value > 0.0 and axis_value >= event.axis_value - 0.1:
				return true
			elif event.axis_value < 0.0 and axis_value <= event.axis_value + 0.1:
				return true
	return false


func _get_joypad_axis(negative_action: StringName, positive_action: StringName, device_id: int) -> float:
	var result := 0.0
	for action in [negative_action, positive_action]:
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				var axis_value := Input.get_joy_axis(device_id, event.axis)
				if action == negative_action:
					result -= clampf(-axis_value if event.axis_value < 0.0 else axis_value, 0.0, 1.0)
				else:
					result += clampf(axis_value if event.axis_value > 0.0 else -axis_value, 0.0, 1.0)
	return clampf(result, -1.0, 1.0)
