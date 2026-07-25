@tool
class_name ShortcutButton
extends Button

## Button that shows a shortcut icon (when available) and triggers its input when clicked.
## Assign a `Shortcut`; the icon updates for the current input method and the text is
## shown or hidden according to icon availability and settings.

const GENERIC_BUTTON_CIRCLE = preload("uid://cqtjp15cpcxov")

## Input methods for which the shortcut icon should be hidden.
@export var hide_icon_on: Array[InputManager.InputMethod] = []

@export_group("Handle Icon And Text")

## Toggle automatic icon/text handling from the assigned `Shortcut`.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var handle_icon_and_text:= true

## If true, keep the button text visible even when no shortcut icon is shown.
@export var keep_visible_if_no_shortcut := false

var _original_text := ""
var _original_icon: Texture2D = null


func _enter_tree() -> void:
	_original_text = text
	_original_icon = icon

	shortcut_in_tooltip = false


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	pressed.connect(_on_pressed)

	if not Engine.is_editor_hint():
		InputManager.input_method_changed.connect(_on_input_method_changed)
		_on_input_method_changed(InputManager.current_input_method)

	_update_icon()


## Set the button's displayed text and keep `_original_text` in sync.
func change_text(new_text: String) -> void:
	_original_text = new_text
	text = _original_text if icon or keep_visible_if_no_shortcut else ""


func _on_visibility_changed() -> void:
	if visible and not icon:
		_update_icon()


func _on_input_method_changed(_new_input_method: InputManager.InputMethod) -> void:
	_update_icon()


func _update_icon() -> void:
	if not visible:
		return

	if Engine.is_editor_hint():
		if shortcut and handle_icon_and_text:
			icon = GENERIC_BUTTON_CIRCLE
		return

	if not shortcut:
		if handle_icon_and_text and InputManager.current_input_method in hide_icon_on:
			icon = null
		return

	if handle_icon_and_text:
		icon = null
	else:
		icon = _original_icon

	for event: InputEvent in shortcut.events:
		var input_method := ControllerIcons.get_input_method(event)

		if input_method == InputManager.InputMethod.UNKNOWN:
			continue

		if hide_icon_on and input_method in hide_icon_on:
			icon = null
			continue

		if handle_icon_and_text:
			icon = ControllerIcons.get_icon(event, get_path())
			text = _original_text if icon or keep_visible_if_no_shortcut else ""


func _on_pressed() -> void:
	ShortcutUtils.process_shortcut_input(shortcut, self)
