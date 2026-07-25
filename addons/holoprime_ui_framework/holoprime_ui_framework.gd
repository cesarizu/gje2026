@tool
extends EditorPlugin

const MULTIPLAYER_INPUT = "MultiplayerInput"
const INPUT_MANAGER = "InputManager"
const CONTROLLER_ICONS = "ControllerIcons"

const _ControllerIconsMainScreen := preload("res://addons/holoprime_ui_framework/input/controller_icons_main_screen.gd")

var _controller_icons_main_screen: Control


func _enter_tree():
	_controller_icons_main_screen = _ControllerIconsMainScreen.new()
	EditorInterface.get_editor_main_screen().add_child(_controller_icons_main_screen)
	_make_visible(false)

	add_autoload_singleton(MULTIPLAYER_INPUT, "res://addons/holoprime_ui_framework/input/multiplayer_input.gd")
	add_autoload_singleton(INPUT_MANAGER, "res://addons/holoprime_ui_framework/input/input_manager.gd")
	add_autoload_singleton(CONTROLLER_ICONS, "res://addons/holoprime_ui_framework/input/controller_icons.gd")

	add_custom_type(
		"ShortcutButton",
		"Button",
		preload("shortcuts/shortcut_button.gd"),
		preload("shortcuts/shortcut_button.svg"),
	)

	add_custom_type(
		"ShortcutContainer",
		"HBoxContainer",
		preload("shortcuts/shortcut_container.gd"),
		preload("shortcuts/shortcut_container.svg"),
	)

	add_custom_type(
		"ShortcutTexture2D",
		"Texture2D",
		preload("shortcuts/shortcut_texture_2d.gd"),
		preload("shortcuts/shortcut_texture_2d.svg"),
	)

	add_custom_type(
		"MultiplayerContext",
		"Node",
		preload("input/multiplayer_context.gd"),
		preload("data_binding/binding_context.svg"),
	)

	add_custom_type(
		"BindingContext",
		"Node",
		preload("data_binding/binding_context.gd"),
		preload("data_binding/binding_context.svg"),
	)

	add_custom_type(
		"ValueBinding",
		"Node",
		preload("data_binding/bindings/value_binding.gd"),
		preload("data_binding/bindings/value_binding.svg"),
	)

	add_custom_type(
		"InstantiateBinding",
		"Node",
		preload("data_binding/bindings/instantiate_binding.gd"),
		preload("data_binding/bindings/instantiate_binding.svg"),
	)

	add_custom_type(
		"ListBinding",
		"Node",
		preload("data_binding/bindings/list_binding.gd"),
		preload("data_binding/bindings/list_binding.svg"),
	)

	add_custom_type(
		"VisibilityBinding",
		"Node",
		preload("data_binding/bindings/visibility_binding.gd"),
		preload("data_binding/bindings/visibility_binding.svg"),
	)

	add_custom_type(
		"DataSourceBinding",
		"Node",
		preload("data_binding/bindings/data_source_binding.gd"),
		preload("data_binding/bindings/data_source_binding.svg"),
	)

	add_custom_type(
		"BindingCommand",
		"Node",
		preload("data_binding/binding_command.gd"),
		preload("data_binding/binding_command.svg"),
	)


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _controller_icons_main_screen:
		_controller_icons_main_screen.visible = visible


func _get_plugin_name() -> String:
	return "Controller Icons"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_base_control().get_theme_icon(&"AnimationLibrary", &"EditorIcons")


func _exit_tree():
	if _controller_icons_main_screen:
		_controller_icons_main_screen.queue_free()
		_controller_icons_main_screen = null

	remove_autoload_singleton(CONTROLLER_ICONS)
	remove_autoload_singleton(INPUT_MANAGER)
	remove_autoload_singleton(MULTIPLAYER_INPUT)

	remove_custom_type("BindingCommand")
	remove_custom_type("DataSourceBinding")
	remove_custom_type("VisibilityBinding")
	remove_custom_type("ListBinding")
	remove_custom_type("InstantiateBinding")
	remove_custom_type("ValueBinding")
	remove_custom_type("BindingContext")
	remove_custom_type("MultiplayerContext")
	remove_custom_type("ShortcutTexture2D")
	remove_custom_type("ShortcutContainer")
	remove_custom_type("ShortcutButton")
