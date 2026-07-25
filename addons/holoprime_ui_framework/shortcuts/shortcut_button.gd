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

## Resolved fresh from the MultiplayerContext ancestor; the binding that drives it may set
## the context's player_index after this node is ready, so it must not be cached.
var _player_index: int:
	get:
		return MultiplayerContext.get_player_index(self)


func _enter_tree() -> void:
	_original_text = text
	_original_icon = icon

	shortcut_in_tooltip = false


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	pressed.connect(_on_pressed)

	if not Engine.is_editor_hint():
		InputManager.input_method_changed.connect(_on_input_method_changed)

	_update_icon()


## Set the button's displayed text and keep `_original_text` in sync.
func change_text(new_text: String) -> void:
	_original_text = new_text
	text = _original_text if icon or keep_visible_if_no_shortcut else ""


func _on_visibility_changed() -> void:
	if visible:
		_update_icon()


func _on_input_method_changed(_new_input_method: InputManager.InputMethod, player_index: int) -> void:
	if not is_inside_tree():
		return

	if player_index == _player_index:
		_update_icon()


func _update_icon() -> void:
	if not visible:
		return

	if Engine.is_editor_hint():
		if shortcut and handle_icon_and_text:
			icon = GENERIC_BUTTON_CIRCLE
		return

	if not shortcut:
		if handle_icon_and_text and InputManager.get_input_method_for(_player_index) in hide_icon_on:
			icon = null
		return

	if handle_icon_and_text:
		icon = null
	else:
		icon = _original_icon

	for event: InputEvent in shortcut.events:
		var input_method := ControllerIcons.get_input_method(event, _player_index)

		if input_method == InputManager.InputMethod.UNKNOWN:
			continue

		if hide_icon_on and input_method in hide_icon_on:
			icon = null
			continue

		if handle_icon_and_text:
			icon = ControllerIcons.get_icon(event, _player_index, get_path())
			text = _original_text if icon or keep_visible_if_no_shortcut else ""


func _on_pressed() -> void:
	ShortcutUtils.process_shortcut_input(shortcut, self)
