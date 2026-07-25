@tool
extends Control

const CONTROLLER_DETECTION_CONFIG_PATH := "res://addons/holoprime_ui_framework/input/controller_detection_config.tres"
const BUILTIN_CONTROLLER_ICONS_DATA = preload("res://addons/holoprime_ui_framework/input/controller_icons_data.tres")
const SHOW_OVERRIDE_MAPPINGS := true

const NON_CONTROLLER_PREFIXES := ["keyboard", "mouse", "touch"]
const ICON_SOURCE_NONE := ""
const ICON_SOURCE_OVERRIDE := "override"
const ICON_SOURCE_FALLBACK := "fallback"
const ICON_CONTEXT_MENU_CLEAR_ID := 0
const FALLBACK_ICON_ALPHA := 0.25
const ICON_PREVIEW_SIZE := 64
const TABLE_ROW_HEIGHT := 72
const JOY_BUTTON_NAME_COLUMN_WIDTH := 320
const JOY_BUTTON_ICON_COLUMN_WIDTH := 96
const JOY_BUTTON_FRIENDLY_NAMES := {
	0: "South / A",
	1: "East / B",
	2: "West / X",
	3: "North / Y",
	4: "Back",
	5: "Guide",
	6: "Start",
	7: "Left Stick",
	8: "Right Stick",
	9: "Left Shoulder",
	10: "Right Shoulder",
	11: "D-Pad Up",
	12: "D-Pad Down",
	13: "D-Pad Left",
	14: "D-Pad Right",
	15: "Misc 1",
	16: "Paddle 1",
	17: "Paddle 2",
	18: "Paddle 3",
	19: "Paddle 4",
	20: "Touchpad",
}

enum EditMode { NONE, BUTTON_ICON, ACTION_ICON }

var _data: ControllerIconsData
var _data_path := ""
var _controller_prefixes: Array[String] = []
var _controller_detection_config: ControllerDetectionConfig

var _edit_mode := EditMode.NONE
var _edit_prefix := ""
var _edit_key := ""

var _status_label: Label
var _path_edit: LineEdit

var _button_tree: Tree
var _button_selection_label: Label

var _action_tree: Tree
var _action_prefix_option: OptionButton
var _action_key_edit: LineEdit
var _action_selection_label: Label
var _remove_selected_action_btn: Button

var _data_file_dialog: EditorFileDialog
var _icon_file_dialog: EditorFileDialog
var _icon_context_menu: PopupMenu
var _context_menu_prefix := ""
var _context_menu_key := ""
var _context_menu_clear_prefix := ""


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	_build_ui()
	_load_data("")


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override(&"separation", 8)
	add_child(root)

	_build_header(root)
	root.add_child(HSeparator.new())

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(tabs)

	_build_joy_button_section(tabs)
	_build_action_section(tabs)
	_build_dialogs()


func _build_header(parent: VBoxContainer) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override(&"separation", 8)
	parent.add_child(title_row)

	var title := Label.new()
	title.text = "Controller Icons"
	title_row.add_child(title)

	var title_spacer := Control.new()
	title_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	title_row.add_child(title_spacer)

	_status_label = Label.new()
	_status_label.modulate.a = 0.7
	title_row.add_child(_status_label)

	var path_row := HBoxContainer.new()
	path_row.add_theme_constant_override(&"separation", 8)
	parent.add_child(path_row)

	var path_label := Label.new()
	path_label.text = "Data File"
	path_row.add_child(path_label)

	_path_edit = LineEdit.new()
	_path_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	_path_edit.placeholder_text = "res://path/to/controller_icons_data.tres"
	_path_edit.text_submitted.connect(_on_path_submitted)
	path_row.add_child(_path_edit)

	var browse_btn := Button.new()
	browse_btn.text = "Browse"
	browse_btn.pressed.connect(_on_browse_data_pressed)
	path_row.add_child(browse_btn)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(_on_load_data_pressed)
	path_row.add_child(load_btn)

	var load_builtin_btn := Button.new()
	load_builtin_btn.text = "Load Builtin"
	load_builtin_btn.pressed.connect(_on_load_builtin_data_pressed)
	path_row.add_child(load_builtin_btn)


func _build_joy_button_section(parent: TabContainer) -> void:
	var section := VBoxContainer.new()
	section.name = "JoyButton Mapping"
	section.size_flags_vertical = SIZE_EXPAND_FILL
	parent.add_child(section)
	parent.set_tab_title(parent.get_tab_count() - 1, "JoyButton Mapping")

	_button_tree = Tree.new()
	_button_tree.size_flags_vertical = SIZE_EXPAND_FILL
	_button_tree.column_titles_visible = true
	_button_tree.hide_root = true
	_button_tree.item_selected.connect(_on_button_tree_selected)
	_button_tree.item_mouse_selected.connect(_on_button_tree_mouse_selected)
	_button_tree.gui_input.connect(_on_button_tree_gui_input)
	section.add_child(_button_tree)


func _build_action_section(parent: TabContainer) -> void:
	var section := VBoxContainer.new()
	section.name = "Action Mappings"
	section.size_flags_vertical = SIZE_EXPAND_FILL
	parent.add_child(section)
	parent.set_tab_title(parent.get_tab_count() - 1, "Action Mappings")

	var form := HBoxContainer.new()
	form.add_theme_constant_override(&"separation", 8)
	section.add_child(form)

	var prefix_label := Label.new()
	prefix_label.text = "Prefix"
	form.add_child(prefix_label)

	_action_prefix_option = OptionButton.new()
	_action_prefix_option.custom_minimum_size.x = 160
	form.add_child(_action_prefix_option)

	var action_label := Label.new()
	action_label.text = "Action"
	form.add_child(action_label)

	_action_key_edit = LineEdit.new()
	_action_key_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	_action_key_edit.placeholder_text = "player_accelerate or action_player_accelerate"
	form.add_child(_action_key_edit)

	var add_action_btn := Button.new()
	add_action_btn.text = "Add / Update Icon..."
	add_action_btn.pressed.connect(_on_add_or_update_action_icon_pressed)
	form.add_child(add_action_btn)

	var action_tools := HBoxContainer.new()
	action_tools.add_theme_constant_override(&"separation", 8)
	section.add_child(action_tools)

	_remove_selected_action_btn = Button.new()
	_remove_selected_action_btn.text = "Remove Selected"
	_remove_selected_action_btn.disabled = true
	_remove_selected_action_btn.pressed.connect(_on_remove_selected_action_pressed)
	action_tools.add_child(_remove_selected_action_btn)

	var action_spacer := Control.new()
	action_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	action_tools.add_child(action_spacer)

	_action_selection_label = Label.new()
	_action_selection_label.modulate.a = 0.7
	action_tools.add_child(_action_selection_label)

	_action_tree = Tree.new()
	_action_tree.size_flags_vertical = SIZE_EXPAND_FILL
	_action_tree.column_titles_visible = true
	_action_tree.hide_root = true
	_action_tree.columns = 3
	_action_tree.set_column_title(0, "Prefix")
	_action_tree.set_column_custom_minimum_width(0, 150)
	_action_tree.set_column_expand(0, false)
	_action_tree.set_column_title(1, "Action Key")
	_action_tree.set_column_expand(1, true)
	_action_tree.set_column_custom_minimum_width(1, 260)
	_action_tree.set_column_title(2, "Icon")
	_action_tree.set_column_expand(2, true)
	_action_tree.set_column_custom_minimum_width(2, 220)
	_action_tree.item_selected.connect(_on_action_tree_selected)
	_action_tree.item_mouse_selected.connect(_on_action_tree_mouse_selected)
	_action_tree.gui_input.connect(_on_action_tree_gui_input)
	section.add_child(_action_tree)


func _build_dialogs() -> void:
	_data_file_dialog = EditorFileDialog.new()
	_data_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_data_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_data_file_dialog.title = "Select Controller Icons Data"
	_data_file_dialog.add_filter("*.tres", "Resource Files")
	_data_file_dialog.add_filter("*.res", "Resource Files")
	_data_file_dialog.file_selected.connect(_on_data_file_selected)
	add_child(_data_file_dialog)

	_icon_file_dialog = EditorFileDialog.new()
	_icon_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_icon_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_icon_file_dialog.title = "Select Icon"
	_icon_file_dialog.add_filter("*.png", "PNG Images")
	_icon_file_dialog.add_filter("*.svg", "SVG Images")
	_icon_file_dialog.add_filter("*.webp", "WebP Images")
	_icon_file_dialog.add_filter("*.jpg,*.jpeg", "JPEG Images")
	_icon_file_dialog.add_filter("*.tres", "Resource Files")
	_icon_file_dialog.add_filter("*.res", "Resource Files")
	_icon_file_dialog.file_selected.connect(_on_icon_file_selected)
	add_child(_icon_file_dialog)

	_icon_context_menu = PopupMenu.new()
	_icon_context_menu.add_item("Clear", ICON_CONTEXT_MENU_CLEAR_ID)
	_icon_context_menu.id_pressed.connect(_on_icon_context_menu_id_pressed)
	add_child(_icon_context_menu)


func _on_browse_data_pressed() -> void:
	if not _data_path.is_empty():
		_data_file_dialog.current_file = _data_path.get_file()
		_data_file_dialog.current_dir = _data_path.get_base_dir()
	_data_file_dialog.popup_centered_ratio(0.7)


func _on_load_data_pressed() -> void:
	_load_data(_path_edit.text)


func _on_load_builtin_data_pressed() -> void:
	_load_data("")


func _on_path_submitted(path: String) -> void:
	_load_data(path)


func _on_data_file_selected(path: String) -> void:
	_path_edit.text = path
	_load_data(path)


func _load_data(path: String) -> void:
	var normalized_path := path.strip_edges()
	var using_fallback := false
	if normalized_path.is_empty():
		normalized_path = BUILTIN_CONTROLLER_ICONS_DATA.resource_path.strip_edges()
		using_fallback = true

	# Should always have a path because the fallback is preloaded, but keep a safe fallback.
	if normalized_path.is_empty():
		if BUILTIN_CONTROLLER_ICONS_DATA:
			_data = BUILTIN_CONTROLLER_ICONS_DATA
			_data_path = ""
			_path_edit.text = ""
			_refresh_ui_state()
			_set_status("Editing fallback icons data.")
			return
		_set_status("No data file selected and fallback icons data is unavailable.", true)
		return

	var loaded := load(normalized_path)
	if not loaded:
		_set_status("Could not load %s" % normalized_path, true)
		return

	if not loaded is ControllerIconsData:
		_set_status("Resource is not ControllerIconsData: %s" % normalized_path, true)
		return

	_data = loaded as ControllerIconsData
	_data_path = normalized_path
	_path_edit.text = normalized_path
	_refresh_ui_state()
	if using_fallback:
		_set_status("Loaded fallback icons data.")
	else:
		_set_status("Loaded %s" % _data_path.get_file())


func _refresh_ui_state() -> void:
	_refresh_controller_prefixes()
	_refresh_action_prefix_options()
	_refresh_joy_button_table()
	_refresh_action_table()
	_update_button_selection_state()
	_update_action_selection_state()

	if not SHOW_OVERRIDE_MAPPINGS:
		_remove_selected_action_btn.disabled = true


func _refresh_controller_prefixes() -> void:
	_controller_prefixes.clear()
	var seen := {}

	var detection_config := _get_controller_detection_config()
	if detection_config:
		for prefix: String in detection_config.controller_match_order:
			_try_add_controller_prefix(prefix, seen)

		for prefix_variant in detection_config.controller_fallbacks.keys():
			_try_add_controller_prefix(str(prefix_variant), seen)
		for fallback_variant in detection_config.controller_fallbacks.values():
			_try_add_controller_prefix(str(fallback_variant), seen)

		for gamepad_prefix_variant in detection_config.gamepad_type_prefixes.values():
			_try_add_controller_prefix(str(gamepad_prefix_variant), seen)

	_try_add_prefixes_from_data(BUILTIN_CONTROLLER_ICONS_DATA, seen)
	if SHOW_OVERRIDE_MAPPINGS:
		_try_add_prefixes_from_data(_data, seen)

	if _controller_prefixes.is_empty():
		_controller_prefixes = ["xbox", "playstation"]


func _try_add_prefixes_from_data(data: ControllerIconsData, seen: Dictionary) -> void:
	if not data:
		return
	for prefix_variant in data.icons.keys():
		_try_add_controller_prefix(str(prefix_variant), seen)


func _try_add_controller_prefix(prefix: String, seen: Dictionary) -> void:
	var trimmed := prefix.strip_edges()
	if trimmed.is_empty():
		return

	var normalized := trimmed.to_lower()
	if NON_CONTROLLER_PREFIXES.has(normalized):
		return

	if seen.has(normalized):
		return

	seen[normalized] = true
	_controller_prefixes.append(trimmed)


func _refresh_action_prefix_options() -> void:
	var previous_selection := _get_selected_action_prefix()
	_action_prefix_option.clear()

	var options: Array[String] = []
	var seen := {}

	_append_action_prefix_option("touch", options, seen)
	for prefix in _controller_prefixes:
		_append_action_prefix_option(prefix, options, seen)

	if SHOW_OVERRIDE_MAPPINGS and _data:
		for prefix_variant in _data.icons.keys():
			_append_action_prefix_option(str(prefix_variant), options, seen)

	for i in range(options.size()):
		_action_prefix_option.add_item(options[i], i)

	if options.is_empty():
		return

	var selected_idx := options.find(previous_selection)
	if selected_idx == -1:
		selected_idx = options.find("touch")
	if selected_idx == -1:
		selected_idx = 0

	_action_prefix_option.select(selected_idx)


func _append_action_prefix_option(prefix: String, options: Array[String], seen: Dictionary) -> void:
	var trimmed := prefix.strip_edges()
	if trimmed.is_empty():
		return

	var normalized := trimmed.to_lower()
	if seen.has(normalized):
		return

	seen[normalized] = true
	options.append(trimmed)


func _get_selected_action_prefix() -> String:
	if _action_prefix_option.get_item_count() == 0:
		return ""

	var selected_id := _action_prefix_option.get_selected_id()
	for i in range(_action_prefix_option.get_item_count()):
		if _action_prefix_option.get_item_id(i) == selected_id:
			return _action_prefix_option.get_item_text(i)

	return _action_prefix_option.get_item_text(0)


func _refresh_joy_button_table() -> void:
	_button_tree.clear()
	_button_tree.columns = 1 + _controller_prefixes.size()
	_button_tree.set_column_title(0, "JoyButton")
	_button_tree.set_column_expand(0, false)
	_button_tree.set_column_custom_minimum_width(0, JOY_BUTTON_NAME_COLUMN_WIDTH)

	for i in range(_controller_prefixes.size()):
		var column := i + 1
		_button_tree.set_column_title(column, _controller_prefixes[i])
		_button_tree.set_column_expand(column, true)
		_button_tree.set_column_custom_minimum_width(column, JOY_BUTTON_ICON_COLUMN_WIDTH)

	var root := _button_tree.create_item()
	for row in _get_joy_button_rows():
		var item := _button_tree.create_item(root)
		var button_name := String(row["name"])
		var button_alias := String(row.get("alias", ""))
		var button_value := int(row["value"])
		var button_key := String(row["key"])
		var preferred_name := button_alias if not button_alias.is_empty() else button_name
		var display_name := _format_joy_button_display_name(preferred_name, button_value)

		item.set_text(0, "%s (%d)" % [display_name, button_value])
		item.set_tooltip_text(0, "JoyButton index %d%s" % [button_value, "" if button_alias.is_empty() else " (%s)" % button_alias])
		item.set_metadata(0, button_key)

		for i in range(_controller_prefixes.size()):
			var prefix := _controller_prefixes[i]
			var icon_mapping := _get_effective_icon_mapping(prefix, button_key)
			var icon := icon_mapping.get("icon") as Texture2D
			var source := String(icon_mapping.get("source", ICON_SOURCE_NONE))
			_set_icon_cell(item, i + 1, icon, source)

		item.set_custom_minimum_height(TABLE_ROW_HEIGHT)


func _refresh_action_table() -> void:
	_action_tree.clear()
	_action_tree.columns = 3
	_action_tree.set_column_title(0, "Prefix")
	_action_tree.set_column_title(1, "Action Key")
	_action_tree.set_column_title(2, "Icon")

	var root := _action_tree.create_item()
	for row in _get_action_rows():
		var item := _action_tree.create_item(root)
		var prefix := String(row["prefix"])
		var action_key := String(row["key"])
		var icon := row["icon"] as Texture2D
		var source := String(row.get("source", ICON_SOURCE_NONE))

		item.set_text(0, prefix)
		item.set_text(1, action_key)
		item.set_metadata(0, prefix)
		item.set_metadata(1, action_key)
		_set_icon_cell(item, 2, icon, source)

		item.set_custom_minimum_height(TABLE_ROW_HEIGHT)


func _set_icon_cell(item: TreeItem, column: int, icon: Texture2D, source := ICON_SOURCE_NONE) -> void:
	item.set_cell_mode(column, TreeItem.CELL_MODE_ICON)
	item.set_text_alignment(column, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_icon_modulate(column, Color(1.0, 1.0, 1.0, _get_icon_alpha_for_source(source)))

	if not icon:
		item.set_icon(column, null)
		item.set_text(column, "")
		item.set_tooltip_text(column, "")
		return

	item.set_icon(column, icon)
	item.set_icon_max_width(column, ICON_PREVIEW_SIZE)
	var icon_path := icon.resource_path
	if icon_path.is_empty():
		item.set_text(column, "")
		item.set_tooltip_text(column, "Embedded texture%s" % _get_source_tooltip_suffix(source))
		return

	item.set_text(column, "")
	item.set_tooltip_text(column, "%s%s" % [icon_path, _get_source_tooltip_suffix(source)])


func _get_icon_alpha_for_source(source: String) -> float:
	if source == ICON_SOURCE_FALLBACK:
		return FALLBACK_ICON_ALPHA
	return 1.0


func _get_source_suffix(source: String) -> String:
	if source == ICON_SOURCE_FALLBACK:
		return " [fallback]"
	return ""


func _get_source_tooltip_suffix(source: String) -> String:
	if source == ICON_SOURCE_FALLBACK:
		return " (fallback from controller_fallbacks or built-in icons data)"
	return ""


func _format_joy_button_display_name(raw_name: String, value: int) -> String:
	var name := raw_name.strip_edges()
	if name.is_empty():
		return String(JOY_BUTTON_FRIENDLY_NAMES.get(value, "Button %d" % value))

	if name.begins_with("JOY_BUTTON_"):
		name = name.trim_prefix("JOY_BUTTON_")

	if name.is_valid_int():
		var numeric_value := int(name)
		return String(JOY_BUTTON_FRIENDLY_NAMES.get(numeric_value, "Button %d" % numeric_value))

	var parts := name.split("_", false)
	for i in range(parts.size()):
		var part := String(parts[i])
		if part.is_empty():
			continue
		if part == part.to_upper() and part.length() <= 3:
			parts[i] = part
		else:
			parts[i] = "%s%s" % [part.substr(0, 1).to_upper(), part.substr(1).to_lower()]

	return " ".join(parts)


func _get_joy_button_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var names_by_value := {}
	for value_variant in _get_joy_button_constant_names_by_value().keys():
		var value := int(value_variant)
		var constant_name := String(_get_joy_button_constant_names_by_value()[value])
		if constant_name == "JOY_BUTTON_MAX":
			continue
		if value < 0:
			continue
		var existing_name := String(names_by_value.get(value, ""))
		names_by_value[value] = _pick_preferred_joy_button_constant(existing_name, constant_name)

	var max_from_constants := -1
	for value_variant in names_by_value.keys():
		max_from_constants = maxi(max_from_constants, int(value_variant))

	var mapped_values: Array[int] = _collect_button_values_from_data(BUILTIN_CONTROLLER_ICONS_DATA)
	if SHOW_OVERRIDE_MAPPINGS:
		mapped_values.append_array(_collect_button_values_from_data(_data))

	var max_from_data := -1
	for mapped_value in mapped_values:
		max_from_data = maxi(max_from_data, mapped_value)

	var max_value := maxi(max_from_constants, max_from_data)

	var sorted_values: Array = []
	for value in range(max_value + 1):
		sorted_values.append(value)

	sorted_values.sort()

	for value_variant in sorted_values:
		var value := int(value_variant)
		var numeric_name := "JOY_BUTTON_%d" % value
		var alias_name := String(names_by_value.get(value, ""))
		rows.append({
			"name": numeric_name,
			"alias": alias_name,
			"value": value,
			"key": "button_%d" % value,
		})

	return rows


func _get_joy_button_constant_names_by_value() -> Dictionary:
	var names_by_value := {
		0: "JOY_BUTTON_A",
		1: "JOY_BUTTON_B",
		2: "JOY_BUTTON_X",
		3: "JOY_BUTTON_Y",
		4: "JOY_BUTTON_BACK",
		5: "JOY_BUTTON_GUIDE",
		6: "JOY_BUTTON_START",
		7: "JOY_BUTTON_LEFT_STICK",
		8: "JOY_BUTTON_RIGHT_STICK",
		9: "JOY_BUTTON_LEFT_SHOULDER",
		10: "JOY_BUTTON_RIGHT_SHOULDER",
		11: "JOY_BUTTON_DPAD_UP",
		12: "JOY_BUTTON_DPAD_DOWN",
		13: "JOY_BUTTON_DPAD_LEFT",
		14: "JOY_BUTTON_DPAD_RIGHT",
		15: "JOY_BUTTON_MISC1",
		16: "JOY_BUTTON_PADDLE1",
		17: "JOY_BUTTON_PADDLE2",
		18: "JOY_BUTTON_PADDLE3",
		19: "JOY_BUTTON_PADDLE4",
		20: "JOY_BUTTON_TOUCHPAD",
	}
	return names_by_value


func _pick_preferred_joy_button_constant(existing_name: String, candidate_name: String) -> String:
	if existing_name.is_empty():
		return candidate_name

	var existing_suffix := _get_joy_button_constant_suffix(existing_name)
	var candidate_suffix := _get_joy_button_constant_suffix(candidate_name)
	var existing_numeric := existing_suffix.is_valid_int()
	var candidate_numeric := candidate_suffix.is_valid_int()

	# Prefer descriptive aliases over numeric aliases (e.g. JOY_BUTTON_A over JOY_BUTTON_0).
	if existing_numeric != candidate_numeric:
		return candidate_name if not candidate_numeric else existing_name

	# If both have the same type, prefer the longer alias as it's usually clearer.
	if candidate_suffix.length() > existing_suffix.length():
		return candidate_name

	return existing_name


func _get_joy_button_constant_suffix(constant_name: String) -> String:
	if constant_name.begins_with("JOY_BUTTON_"):
		return constant_name.trim_prefix("JOY_BUTTON_")
	return constant_name


func _collect_button_values_from_data(data: ControllerIconsData) -> Array[int]:
	var values := {}
	if not data:
		return []

	for prefix_variant in data.icons.keys():
		var prefix := str(prefix_variant)
		if NON_CONTROLLER_PREFIXES.has(prefix.to_lower()):
			continue

		var prefix_map_variant := data.icons.get(prefix_variant, {})
		if not (prefix_map_variant is Dictionary):
			continue

		var prefix_map := prefix_map_variant as Dictionary
		for key_variant in prefix_map.keys():
			var key := str(key_variant)
			if not key.begins_with("button_"):
				continue

			var suffix := key.substr(7)
			if not suffix.is_valid_int():
				continue

			values[int(suffix)] = true

	var result: Array[int] = []
	for value_variant in values.keys():
		result.append(int(value_variant))

	return result


func _get_action_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var unique_actions := _collect_action_keys()
	for pair_key_variant in unique_actions.keys():
		var pair := unique_actions[pair_key_variant] as Dictionary
		var prefix := String(pair.get("prefix", ""))
		var key := String(pair.get("key", ""))
		var icon_mapping := _get_effective_icon_mapping(prefix, key)

		rows.append({
			"prefix": prefix,
			"key": key,
			"icon": icon_mapping.get("icon") as Texture2D,
			"source": String(icon_mapping.get("source", ICON_SOURCE_NONE)),
		})

	rows.sort_custom(_sort_action_rows)
	return rows


func _collect_action_keys() -> Dictionary:
	var result := {}
	_collect_action_keys_from_data(BUILTIN_CONTROLLER_ICONS_DATA, result)
	if SHOW_OVERRIDE_MAPPINGS:
		_collect_action_keys_from_data(_data, result)
	return result


func _collect_action_keys_from_data(data: ControllerIconsData, output: Dictionary) -> void:
	if not data:
		return

	for prefix_variant in data.icons.keys():
		var prefix := str(prefix_variant)
		var prefix_map_variant := data.icons.get(prefix_variant, {})
		if not (prefix_map_variant is Dictionary):
			continue

		var prefix_map := prefix_map_variant as Dictionary
		for key_variant in prefix_map.keys():
			var key := str(key_variant)
			if not key.begins_with("action_"):
				continue

			var id := "%s|%s" % [prefix.to_lower(), key]
			if output.has(id):
				continue

			output[id] = {
				"prefix": prefix,
				"key": key,
			}


func _sort_action_rows(a: Dictionary, b: Dictionary) -> bool:
	var prefix_a := String(a.get("prefix", ""))
	var prefix_b := String(b.get("prefix", ""))
	if prefix_a == prefix_b:
		return String(a.get("key", "")) < String(b.get("key", ""))
	return prefix_a < prefix_b


func _on_button_tree_selected() -> void:
	_update_button_selection_state()


func _on_action_tree_selected() -> void:
	_update_action_selection_state()


func _on_button_tree_mouse_selected(_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	var context := _get_button_context_from_position(_position)
	if context.is_empty():
		return

	_open_quick_load_for_icon(EditMode.BUTTON_ICON, String(context["prefix"]), String(context["key"]))


func _on_action_tree_mouse_selected(_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	var context := _get_action_context_from_position(_position)
	if context.is_empty():
		return

	_open_quick_load_for_icon(EditMode.ACTION_ICON, String(context["prefix"]), String(context["key"]))


func _on_button_tree_gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if not mouse_button:
		return
	if not mouse_button.pressed:
		return
	if mouse_button.button_index != MOUSE_BUTTON_RIGHT:
		return

	var context := _get_button_context_from_position(mouse_button.position)
	if context.is_empty():
		return

	_open_icon_context_menu(context)
	_button_tree.accept_event()


func _on_action_tree_gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if not mouse_button:
		return
	if not mouse_button.pressed:
		return
	if mouse_button.button_index != MOUSE_BUTTON_RIGHT:
		return

	var context := _get_action_context_from_position(mouse_button.position)
	if context.is_empty():
		return

	_open_icon_context_menu(context)
	_action_tree.accept_event()


func _update_button_selection_state() -> void:
	if not _button_selection_label:
		return

	var context := _get_selected_button_context()
	if context.is_empty():
		_button_selection_label.text = ""
		return

	var prefix := String(context["prefix"])
	var key := String(context["key"])
	var icon_mapping := _get_effective_icon_mapping(prefix, key)
	var current_icon := icon_mapping.get("icon") as Texture2D
	var source := String(icon_mapping.get("source", ICON_SOURCE_NONE))
	var icon_path := _get_icon_path_or_placeholder(current_icon)
	_button_selection_label.text = "%s / %s -> %s%s" % [prefix, key, icon_path, _get_source_suffix(source)]


func _update_action_selection_state() -> void:
	var context := _get_selected_action_context()
	var has_context := not context.is_empty()
	_remove_selected_action_btn.disabled = not has_context

	if not has_context:
		_action_selection_label.text = "Select an action row to edit."
		return

	var prefix := String(context["prefix"])
	var key := String(context["key"])
	var has_override := _get_override_icon_mapping(prefix, key) != null
	_remove_selected_action_btn.disabled = not has_override
	var icon_mapping := _get_effective_icon_mapping(prefix, key)
	var current_icon := icon_mapping.get("icon") as Texture2D
	var source := String(icon_mapping.get("source", ICON_SOURCE_NONE))
	var icon_path := _get_icon_path_or_placeholder(current_icon)
	_action_selection_label.text = "%s / %s -> %s%s" % [prefix, key, icon_path, _get_source_suffix(source)]


func _get_icon_path_or_placeholder(icon: Texture2D) -> String:
	if not icon:
		return "-"
	if icon.resource_path.is_empty():
		return "[embedded]"
	return icon.resource_path


func _get_selected_button_context() -> Dictionary:
	if not _button_tree:
		return {}

	var selected_item := _button_tree.get_selected()
	if not selected_item:
		return {}

	var selected_column := _button_tree.get_selected_column()
	if selected_column <= 0:
		return {}

	var prefix_index := selected_column - 1
	if prefix_index < 0 or prefix_index >= _controller_prefixes.size():
		return {}

	var key := str(selected_item.get_metadata(0))
	if key.is_empty():
		return {}

	return {
		"prefix": _controller_prefixes[prefix_index],
		"key": key,
	}


func _get_selected_action_context() -> Dictionary:
	if not _action_tree:
		return {}

	var selected_item := _action_tree.get_selected()
	if not selected_item:
		return {}

	var prefix := str(selected_item.get_metadata(0))
	var key := str(selected_item.get_metadata(1))
	if prefix.is_empty() or key.is_empty():
		return {}

	return {
		"prefix": prefix,
		"key": key,
	}


func _get_button_context_from_position(position: Vector2) -> Dictionary:
	if not _button_tree:
		return {}

	var item := _button_tree.get_item_at_position(position)
	if not item:
		return {}

	var column := _button_tree.get_column_at_position(position)
	if column <= 0:
		return {}

	var key := str(item.get_metadata(0))
	if key.is_empty():
		return {}

	item.select(column)

	var prefix_index := column - 1
	if prefix_index < 0 or prefix_index >= _controller_prefixes.size():
		return {}

	return {
		"prefix": _controller_prefixes[prefix_index],
		"key": key,
	}


func _get_action_context_from_position(position: Vector2) -> Dictionary:
	if not _action_tree:
		return {}

	var item := _action_tree.get_item_at_position(position)
	if not item:
		return {}

	var column := _action_tree.get_column_at_position(position)
	if column != 2:
		return {}

	var prefix := str(item.get_metadata(0))
	var key := str(item.get_metadata(1))
	if prefix.is_empty() or key.is_empty():
		return {}

	item.select(column)

	return {
		"prefix": prefix,
		"key": key,
	}


func _on_add_or_update_action_icon_pressed() -> void:
	var prefix := _get_selected_action_prefix()
	var action_key := _normalize_action_key(_action_key_edit.text)
	if prefix.is_empty():
		_set_status("Select a prefix first.", true)
		return
	if action_key.is_empty():
		_set_status("Enter an action name first.", true)
		return

	_action_key_edit.text = action_key
	_open_icon_picker(EditMode.ACTION_ICON, prefix, action_key)


func _on_remove_selected_action_pressed() -> void:
	var context := _get_selected_action_context()
	if context.is_empty():
		return

	var prefix := String(context["prefix"])
	var key := String(context["key"])
	if not _get_override_icon_mapping(prefix, key):
		_set_status("No override to remove for %s / %s." % [prefix, key], true)
		return

	_set_icon_mapping(prefix, key, null)
	if _save_data():
		_refresh_ui_state()
		_set_status("Removed %s / %s" % [prefix, key])


func _open_icon_context_menu(context: Dictionary) -> void:
	if not _icon_context_menu:
		return

	var prefix := String(context.get("prefix", ""))
	var key := String(context.get("key", ""))
	if prefix.is_empty() or key.is_empty():
		return

	_context_menu_prefix = prefix
	_context_menu_key = key
	_context_menu_clear_prefix = _find_clear_prefix_in_loaded_data(prefix, key)

	var can_clear := not _context_menu_clear_prefix.is_empty()
	_icon_context_menu.set_item_disabled(ICON_CONTEXT_MENU_CLEAR_ID, not can_clear)
	_icon_context_menu.position = DisplayServer.mouse_get_position()
	_icon_context_menu.reset_size()
	_icon_context_menu.popup()


func _on_icon_context_menu_id_pressed(id: int) -> void:
	if id != ICON_CONTEXT_MENU_CLEAR_ID:
		return

	var prefix := _context_menu_prefix
	var key := _context_menu_key
	var clear_prefix := _context_menu_clear_prefix

	if prefix.is_empty() or key.is_empty():
		_reset_icon_context_menu_context()
		return

	if clear_prefix.is_empty():
		_set_status("No mapping to clear in the loaded file for %s / %s." % [prefix, key], true)
		_reset_icon_context_menu_context()
		return

	_set_icon_mapping(clear_prefix, key, null)
	_refresh_ui_state()

	if _save_data():
		_set_status("Cleared %s / %s (source: %s)" % [prefix, key, clear_prefix])
	else:
		_set_status("Cleared %s / %s in memory, but failed to save." % [prefix, key], true)

	_reset_icon_context_menu_context()


func _reset_icon_context_menu_context() -> void:
	_context_menu_prefix = ""
	_context_menu_key = ""
	_context_menu_clear_prefix = ""


func _find_clear_prefix_in_loaded_data(prefix: String, key: String) -> String:
	if not _data:
		return ""

	var prefix_fallback_chain := _get_prefix_fallback_chain(prefix)
	for fallback_prefix in prefix_fallback_chain:
		var prefix_map := _get_prefix_icon_map_from_data(_data, fallback_prefix)
		if not prefix_map.has(key):
			continue
		if prefix_map.get(key) is Texture2D:
			return fallback_prefix

	return ""


func _normalize_action_key(raw_text: String) -> String:
	var action_key := raw_text.strip_edges().replace(" ", "_")
	if action_key.is_empty():
		return ""
	if action_key.begins_with("action_"):
		return action_key
	return "action_%s" % action_key


func _open_icon_picker(mode: EditMode, prefix: String, key: String) -> void:
	if not _data:
		_set_status("Load a ControllerIconsData resource first.", true)
		return

	_edit_mode = mode
	_edit_prefix = prefix
	_edit_key = key

	var title := "Select Icon for %s / %s" % [prefix, key]
	_icon_file_dialog.title = title
	_icon_file_dialog.popup_centered_ratio(0.7)


func _open_quick_load_for_icon(mode: EditMode, prefix: String, key: String) -> void:
	if not _data:
		_set_status("Load a ControllerIconsData file to save overrides.", true)
		return

	_edit_mode = mode
	_edit_prefix = prefix
	_edit_key = key

	var title := "Select Icon for %s / %s" % [prefix, key]

	if not EditorInterface.has_method(&"popup_quick_open"):
		_icon_file_dialog.title = title
		_icon_file_dialog.popup_centered_ratio(0.7)
		return

	EditorInterface.popup_quick_open(Callable(self, "_on_quick_load_icon_selected"), PackedStringArray(["Texture2D"]))


func _on_quick_load_icon_selected(path: String) -> void:
	_apply_selected_icon_path(path)


func _on_icon_file_selected(path: String) -> void:
	_apply_selected_icon_path(path)


func _apply_selected_icon_path(path: String) -> void:
	if _edit_mode == EditMode.NONE:
		return

	if path.strip_edges().is_empty():
		_reset_edit_context()
		return

	var icon := load(path) as Texture2D
	if not icon:
		_set_status("Selected file is not a Texture2D: %s" % path, true)
		_reset_edit_context()
		return

	if not _data:
		_set_status("Load a ControllerIconsData file to save overrides.", true)
		_reset_edit_context()
		return

	var edited_prefix := _edit_prefix
	var edited_key := _edit_key

	_set_icon_mapping(edited_prefix, edited_key, icon)
	_refresh_ui_state()

	if _save_data():
		var mode_note := ""
		if not SHOW_OVERRIDE_MAPPINGS:
			mode_note = " (fallback-only view active)"
		_set_status("Updated %s / %s%s" % [edited_prefix, edited_key, mode_note])
	else:
		_set_status("Updated %s / %s in memory, but failed to save." % [edited_prefix, edited_key], true)

	_reset_edit_context()


func _reset_edit_context() -> void:
	_edit_mode = EditMode.NONE
	_edit_prefix = ""
	_edit_key = ""


func _set_icon_mapping(prefix: String, key: String, icon: Texture2D) -> void:
	if not _data:
		return

	var icons := _data.icons.duplicate(true)
	var resolved_prefix := _resolve_existing_prefix_key(icons, prefix)
	var prefix_map: Dictionary = {}
	var existing_map := icons.get(resolved_prefix, {})
	if existing_map is Dictionary:
		prefix_map = (existing_map as Dictionary).duplicate(true)

	if icon:
		prefix_map[key] = icon
	else:
		prefix_map.erase(key)

	if prefix_map.is_empty():
		icons.erase(resolved_prefix)
	else:
		icons[resolved_prefix] = prefix_map

	_data.icons = icons
	_data.emit_changed()


func _resolve_existing_prefix_key(icons: Dictionary, prefix: String) -> String:
	if icons.has(prefix):
		return prefix

	var normalized := prefix.to_lower()
	for existing_prefix_variant in icons.keys():
		var existing_prefix := str(existing_prefix_variant)
		if existing_prefix.to_lower() == normalized:
			return existing_prefix

	return prefix


func _get_effective_icon_mapping(prefix: String, key: String) -> Dictionary:
	var prefix_fallback_chain := _get_prefix_fallback_chain(prefix)
	var is_using_builtin_data := _is_using_builtin_icons_data()
	if SHOW_OVERRIDE_MAPPINGS:
		var override_mapping := _find_icon_mapping_in_chain(_data, prefix_fallback_chain, key)
		var override_icon := override_mapping.get("icon") as Texture2D
		if override_icon:
			var override_source := ICON_SOURCE_FALLBACK if bool(override_mapping.get("used_config_fallback", false)) else ICON_SOURCE_OVERRIDE
			return {
				"icon": override_icon,
				"source": override_source,
			}

	var builtin_mapping := _find_icon_mapping_in_chain(BUILTIN_CONTROLLER_ICONS_DATA, prefix_fallback_chain, key)
	var builtin_icon := builtin_mapping.get("icon") as Texture2D
	if builtin_icon:
		var used_config_fallback := bool(builtin_mapping.get("used_config_fallback", false))
		var fallback_to_builtin_data := not is_using_builtin_data
		var builtin_source := ICON_SOURCE_FALLBACK if (used_config_fallback or fallback_to_builtin_data) else ICON_SOURCE_NONE
		return {
			"icon": builtin_icon,
			"source": builtin_source,
		}

	return {
		"icon": null,
		"source": ICON_SOURCE_NONE,
	}


func _find_icon_mapping_in_chain(data: ControllerIconsData, prefix_fallback_chain: Array[String], key: String) -> Dictionary:
	for i in range(prefix_fallback_chain.size()):
		var fallback_prefix := prefix_fallback_chain[i]
		var icon := _get_icon_mapping_from_data(data, fallback_prefix, key)
		if icon:
			return {
				"icon": icon,
				"used_config_fallback": i > 0,
			}

	return {
		"icon": null,
		"used_config_fallback": false,
	}


func _is_using_builtin_icons_data() -> bool:
	if not _data:
		return false

	var builtin_path := BUILTIN_CONTROLLER_ICONS_DATA.resource_path.strip_edges()
	if builtin_path.is_empty():
		return _data == BUILTIN_CONTROLLER_ICONS_DATA

	var current_path := _data.resource_path.strip_edges()
	if current_path.is_empty():
		current_path = _data_path.strip_edges()

	return current_path.to_lower() == builtin_path.to_lower()


func _get_override_icon_mapping(prefix: String, key: String) -> Texture2D:
	return _get_icon_mapping_from_data(_data, prefix, key)


func _get_prefix_fallback_chain(prefix: String) -> Array[String]:
	var chain: Array[String] = []
	var visited := {}
	var current_prefix := prefix.strip_edges()
	var config := _get_controller_detection_config()

	while not current_prefix.is_empty():
		var normalized := current_prefix.to_lower()
		if visited.has(normalized):
			break

		visited[normalized] = true
		chain.append(current_prefix)

		if not config:
			break

		current_prefix = _get_fallback_prefix(config, current_prefix)

	return chain


func _get_fallback_prefix(config: ControllerDetectionConfig, prefix: String) -> String:
	for fallback_key_variant in config.controller_fallbacks.keys():
		var fallback_key := str(fallback_key_variant)
		if fallback_key.to_lower() != prefix.to_lower():
			continue
		return str(config.controller_fallbacks.get(fallback_key_variant, "")).strip_edges()

	return ""


func _get_controller_detection_config() -> ControllerDetectionConfig:
	if _controller_detection_config:
		return _controller_detection_config

	_controller_detection_config = load(CONTROLLER_DETECTION_CONFIG_PATH) as ControllerDetectionConfig
	return _controller_detection_config


func _get_icon_mapping_from_data(data: ControllerIconsData, prefix: String, key: String) -> Texture2D:
	var prefix_map := _get_prefix_icon_map_from_data(data, prefix)
	return prefix_map.get(key) as Texture2D


func _get_prefix_icon_map_from_data(data: ControllerIconsData, prefix: String) -> Dictionary:
	if not data:
		return {}

	if data.icons.has(prefix):
		var direct_map := data.icons.get(prefix, {})
		if direct_map is Dictionary:
			return direct_map as Dictionary

	var normalized := prefix.to_lower()
	for existing_prefix_variant in data.icons.keys():
		var existing_prefix := str(existing_prefix_variant)
		if existing_prefix.to_lower() != normalized:
			continue
		var map_variant := data.icons.get(existing_prefix, {})
		if map_variant is Dictionary:
			return map_variant as Dictionary
		break

	return {}


func _save_data() -> bool:
	if not _data:
		_set_status("No ControllerIconsData loaded.", true)
		return false
	if _data_path.is_empty():
		_set_status("Data path is empty.", true)
		return false

	var save_error := ResourceSaver.save(_data, _data_path)
	if save_error != OK:
		push_error("Controller Icons: failed to save '%s' (error %d)" % [_data_path, save_error])
		_set_status("Save failed (error %d)." % save_error, true)
		return false

	return true


func _set_status(text: String, is_error := false) -> void:
	if not _status_label:
		return

	_status_label.text = text
	if is_error:
		_status_label.modulate = Color(1.0, 0.55, 0.55, 1.0)
	else:
		_status_label.modulate = Color(1.0, 1.0, 1.0, 0.75)
