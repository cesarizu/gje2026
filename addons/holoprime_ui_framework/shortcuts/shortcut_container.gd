extends HBoxContainer

## A container that manages shortcut buttons and automatically updates their icons.
##
## This container scans its Button children during [method _enter_tree] and manages
## those with valid shortcuts. It listens to input method changes (keyboard/mouse vs
## controller) and updates button icons accordingly using ControllerIcons.
##
## When a button is pressed, it simulates the shortcut's input event, either by
## forwarding it to the top menu in MenuStack or parsing it directly via Input.
##
## Usage: Add Button nodes with shortcuts as children. The container will automatically
## manage their icons and handle their pressed signals.

## Array of Button nodes that have valid shortcuts.
##
## Populated during [method _enter_tree] by scanning children for Button nodes
## with valid shortcuts. These buttons are monitored for pressed signals and
## have their icons updated when the input method changes.
var _buttons: Array[Button] = []


func _enter_tree() -> void:
	for children in get_children():
		var button := children as Button
		if button and button.shortcut and button.shortcut.has_valid_event():
			button.pressed.connect(_on_button_pressed.bind(button))
			button.focus_mode = Control.FOCUS_NONE
			_buttons.push_back(button)


func _ready() -> void:
	InputManager.input_method_changed.connect(_on_input_method_changed)
	_on_input_method_changed(InputManager.current_input_method)


func _on_input_method_changed(_new_input_method: InputManager.InputMethod) -> void:
	for button in _buttons:
		for event: InputEvent in button.shortcut.events:
			button.icon = ControllerIcons.get_icon(event)


func _on_button_pressed(button: Button) -> void:
	ShortcutUtils.process_shortcut_input(button.shortcut, self)
