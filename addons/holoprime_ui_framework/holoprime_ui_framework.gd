@tool
extends EditorPlugin

const CONTROLLER_ICONS = "ControllerIcons"
const INPUT_MANAGER = "InputManager"


func _enter_tree():
	add_autoload_singleton(CONTROLLER_ICONS, "res://addons/holoprime_ui_framework/input/controller_icons.gd")
	add_autoload_singleton(INPUT_MANAGER, "res://addons/holoprime_ui_framework/input/input_manager.gd")

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
		"BindingAction",
		"Node",
		preload("data_binding/binding_action.gd"),
		preload("data_binding/binding_action.svg"),
	)


func _exit_tree():
	remove_autoload_singleton(CONTROLLER_ICONS)
	remove_autoload_singleton(INPUT_MANAGER)

	remove_custom_type("ShortcutButton")
	remove_custom_type("ShortcutTexture2D")
