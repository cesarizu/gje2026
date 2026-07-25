class_name DebugUI
extends CanvasLayer

const GRID_SIZE := Vector2(250, 250)
const GRID_SPACING := 64

var container: Container
var sub_container: Container


func _enter_tree() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	container = %VBoxContainer

	hide()

	InputManager.input_method_changed.connect(_on_input_method_changed)
	visibility_changed.connect(_on_visibility_changed)


#region Lifecycle


func _on_input_method_changed(_new_input_method: InputManager.InputMethod) -> void:
	_try_grab_focus.call_deferred()


func _on_visibility_changed() -> void:
	if visible:
		_add_buttons()
	else:
		for child in container.get_children():
			child.queue_free()

	_try_grab_focus.call_deferred()


func _add_buttons() -> void:
	pass


func _try_grab_focus() -> void:
	if visible and InputManager.use_gamepad and container.get_child_count() > 1:
		var first_sub_container := container.get_child(1)
		if first_sub_container.get_child_count() > 0:
			first_sub_container.get_child(0).grab_focus()


func _shortcut_input(event: InputEvent) -> void:
	# Close with ESC/B when visible
	if visible and event.is_action_pressed(&"menu_back"):
		visible = false
		get_viewport().set_input_as_handled()
		return

	# Toggle with F3
	if event is InputEventKey and Input.is_action_pressed(&"debug_open_menu_1"):
		get_viewport().set_input_as_handled()
		visible = !visible
		return

	# Toggle with both sticks pressed
	var a := Input.is_action_pressed(&"debug_open_menu_1") and event.is_action_pressed(&"debug_open_menu_2")
	var b := Input.is_action_pressed(&"debug_open_menu_2") and event.is_action_pressed(&"debug_open_menu_1")

	if a or b:
		get_viewport().set_input_as_handled()
		visible = !visible
		return


func _on_close_button_pressed() -> void:
	hide()


#endregion

#region Utility


func _add_section(section_name: String) -> void:
	var title := Label.new()
	title.text = section_name
	title.theme_type_variation = &"SectionLabel"
	container.add_child(title)

	sub_container = HFlowContainer.new()
	container.add_child(sub_container)


func _add_button(text: String, color: Color, action: Callable) -> void:
	_add_generic_button(text, false, false, color, action)


func _add_toggle_button(text: String, button_pressed: bool, color: Color, action: Callable) -> void:
	_add_generic_button(text, true, button_pressed, color, action)


func _add_generic_button(text: String, is_toggle: bool, button_pressed: bool, color: Color, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD
	button.theme_type_variation = &"DebugButton"
	button.custom_minimum_size = GRID_SIZE
	button.self_modulate = color

	button.toggle_mode = is_toggle
	if is_toggle:
		button.button_pressed = button_pressed
		button.toggled.connect(action)
	else:
		button.pressed.connect(action)

	sub_container.add_child(button)


func _add_dropdown(text: String, values: Array[Variant], variable: StringName) -> void:
	var dropdown := MenuButton.new()

	var selected := func(index: int) -> void:
		var value: Variant = values[index]
		dropdown.text = "%s: %s" % [text, value]
		set(variable, value)

	dropdown.text = text
	dropdown.flat = false
	dropdown.theme_type_variation = &"DebugMenuButton"
	dropdown.custom_minimum_size = GRID_SIZE * Vector2(2, 1) + Vector2(GRID_SPACING, 0)
	dropdown.get_popup().index_pressed.connect(selected)

	for value: Variant in values:
		dropdown.get_popup().add_item(value)

	sub_container.add_child(dropdown)

	selected.call(0)


#endregion

#region UI

@export_group("Rendering")
@export var texel_density_material: ShaderMaterial


func _add_texel_density_button() -> void:
	_add_button("Texel Density", Color.PALE_VIOLET_RED, _show_texel_density)


func _show_texel_density() -> void:
	for geometry: MeshInstance3D in HoloprimeUtils.find_by_class(get_tree().root, MeshInstance3D):
		var material := geometry.get_active_material(0)
		var texel_density := texel_density_material.duplicate()
		if material is StandardMaterial3D:
			texel_density.set_shader_parameter("original_texture", material.albedo_texture)
		geometry.material_override = texel_density


#endregion

#region UI


func _add_cycle_input_method_button() -> void:
	_add_button("Cycle Input Method", Color.ORANGE, _cycle_input_method)


func _cycle_input_method() -> void:
	@warning_ignore("int_as_enum_without_cast")
	InputManager.forced_input_method = (InputManager.forced_input_method + 1) % InputManager.InputMethod.size()


#endregion

#region Time


func _add_time_scale_section() -> void:
	_add_section("Time")
	_add_button("Time Scale -", Color.GRAY, func() -> void: Engine.time_scale /= 1.5)
	_add_button("Time Scale =", Color.GRAY, func() -> void: Engine.time_scale = 1.0)
	_add_button("Time Scale +", Color.GRAY, func() -> void: Engine.time_scale *= 1.5)

#endregion

#region Logs


func _add_log_toggle_button(text: String, channels: Array[StringName]) -> void:
	var button_pressed := channels.any(func(channel) -> bool: return Log.is_enabled(channel, Log.Level.DEBUG))
	_add_toggle_button(text, button_pressed, Color.DODGER_BLUE, _toggle_log.bind(channels))


func _toggle_log(toggled_on: bool, channels: Array[StringName]) -> void:
	for channel in channels:
		Log.set_enabled(channel, Log.Level.DEBUG, toggled_on)


#endregion
