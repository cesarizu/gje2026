class_name ListBinding
extends Binding

## This class represents a list binding for data contexts in the UI framework that connects a data property representing a list with UI elements.
## It will try to instantiate item scenes for each item in the list based on the provided configuration: first keyed scenes, then default scene, then template node, and finally just setting data sources directly.

## The property path to bind for tracking the selected item index. When set, grabs focus on the item at that index after instantiation.
@export var selected_item_idx_property_path: StringName:
	set(value):
		selected_item_idx_property_path = value
		_refresh_binding()

## The property path on the list item to bind to. If empty, sets the item's binding context data source.
@export var item_target_property_path: StringName:
	set(value):
		item_target_property_path = value
		_refresh_binding()

## Whether to hide the parent node when the list is empty
@export var hide_when_empty: bool = false:
	set(value):
		hide_when_empty = value
		_refresh_binding()

@export_category("Item Scenes")

## The scene to be used when instantiating items on this list
@export var item_scene: PackedScene

## The node path to a template item to duplicate for each list item
@export_node_path var template_item_node_path: NodePath

## The expression to use as key for selecting item scenes from the dictionary.
@export var item_scene_key_expression: StringName

## A dictionary mapping keys to item scenes for instantiation.
@export var item_scenes_by_key: Dictionary[StringName, PackedScene] = {}

## List of instantiated children (non-binding nodes)
var _instantiated_children: Array[Node] = []


func _ready() -> void:
	if template_item_node_path:
		get_node(template_item_node_path).hide()
	super()


func _refresh_binding() -> void:
	if _bound_data_source == null:
		return

	var list := BindingUtils.get_array_from_variant(bound_value)
	var parent := get_parent()

	Log.debug(&"ListBinding", "%s: Refreshing with value: %s=%s" % [self, debug_source, list])

	# If we have keyed instantiation, clear the instantiated children to prevent reusing items that don't match the type
	if item_scene_key_expression:
		if not parent.is_node_ready():
			await parent.ready

		for node in _instantiated_children:
			node.get_parent().remove_child(node)
			node.queue_free()

		_instantiated_children.clear()

	# Filter out items that don't have a scene to instantiate
	if item_scene_key_expression and not item_scene:
		list = list.filter(func(item):
			var key := StringName(str(BindingUtils.evaluate_expression(item, item_scene_key_expression)))
			return key in item_scenes_by_key
		)

	# Handle hiding parent when list is empty
	if hide_when_empty:
		parent.visible = not list.is_empty()

	# If having to instantiate a scene, check each item for the type or instantiate the default scene
	if item_scene_key_expression or item_scene:
		_instantiated_children = await BindingUtils.setup_children_nodes(parent, list, item_target_property_path, func(item):
			# Try to instantiate item scenes based on key property if specified and found in the dictionary.
			if item_scene_key_expression:
				var key := StringName(str(BindingUtils.evaluate_expression(item, item_scene_key_expression)))
				if key in item_scenes_by_key:
					return item_scenes_by_key[key].instantiate()

			# Fallback to default item scene if specified.
			if item_scene:
				return item_scene.instantiate()
		, _instantiated_children, self)
		_setup_list_item_events()
		_handle_selected_item()
		return

	# If the item scene path is specified, duplicate that node for each item.
	if template_item_node_path:
		var item_template := get_node(template_item_node_path)
		_instantiated_children = await BindingUtils.setup_children_nodes(parent, list, item_target_property_path, func(item):
			var new_item := item_template.duplicate(DUPLICATE_SCRIPTS | DUPLICATE_SIGNALS)
			new_item.visible = true
			_fix_signals(new_item)
			return new_item
		, _instantiated_children, self)
		_setup_list_item_events()
		_handle_selected_item()
		return

	# Otherwise, just set up children data sources directly on existing instantiated children.
	if _instantiated_children.is_empty():
		# If no children exist yet, fallback to getting bindable children from parent
		_instantiated_children = await BindingUtils.set_children_data_sources(parent, list, item_target_property_path)
	else:
		# Use existing instantiated children
		_instantiated_children = await BindingUtils.set_children_data_sources_on_nodes(_instantiated_children, list, item_target_property_path)
	_setup_list_item_events()
	_handle_selected_item()


func _setup_list_item_events() -> void:
	# Connect to item signals for all instantiated children
	for child in _instantiated_children:
		# Connect to the pressed signal if it exists
		if child.has_signal(&"pressed"):
			if not child.is_connected(&"pressed", _on_item_pressed):
				child.connect(&"pressed", _on_item_pressed.bind(child))

		# Connect to focus signals if they exist
		if child.has_signal(&"mouse_entered"):
			if not child.is_connected(&"mouse_entered", _on_item_focused):
				child.connect(&"mouse_entered", _on_item_focused.bind(child, true))
		if child.has_signal(&"mouse_exited"):
			if not child.is_connected(&"mouse_exited", _on_item_focused):
				child.connect(&"mouse_exited", _on_item_focused.bind(child, false))
		if child.has_signal(&"focus_entered"):
			if not child.is_connected(&"focus_entered", _on_item_focused):
				child.connect(&"focus_entered", _on_item_focused.bind(child, true))
		if child.has_signal(&"focus_exited"):
			if not child.is_connected(&"focus_exited", _on_item_focused):
				child.connect(&"focus_exited", _on_item_focused.bind(child, false))


func _handle_selected_item() -> void:
	if not selected_item_idx_property_path:
		return

	# Get the selected index from the data source
	var selected_idx := BindingUtils.evaluate_expression(_bound_data_source, selected_item_idx_property_path)
	if selected_idx == null or not (selected_idx is int):
		return

	# Ensure the index is valid
	if selected_idx < 0 or selected_idx >= _instantiated_children.size():
		return

	var selected_child: Node = _instantiated_children[selected_idx]

	# Grab focus on the selected item
	if selected_child.has_method(&"grab_focus"):
		selected_child.grab_focus()


func _on_item_pressed(item: Node) -> void:
	var parent_context := BindingContext.get_parent_context(item.get_parent())
	if parent_context:
		var source_context := BindingContext.get_self_context(item)
		parent_context.push_action(&"pressed", source_context)


func _on_item_focused(item: Node, focused: bool) -> void:
	var parent_context := BindingContext.get_parent_context(item.get_parent())
	if parent_context:
		var source_context := BindingContext.get_self_context(item)
		parent_context.push_action(&"focused", source_context, focused)


func _fix_signals(new_item: Node) -> void:
	var signals := []

	for sig in new_item.get_signal_list():
		for conn in new_item.get_signal_connection_list(sig["name"]):
			if ConnectFlags.CONNECT_APPEND_SOURCE_OBJECT & conn["flags"] != 0:
				signals.append(conn)

	for conn in signals:
		new_item.disconnect(conn["signal"].get_name(), conn["callable"])
		new_item.connect(conn["signal"].get_name(), func(): conn["callable"].get_object().call(conn["callable"].get_method(), new_item))


func _to_string() -> String:
	var parent_name := get_parent().name if get_parent() else "null"

	return "ListBinding(%s=%s)" % [parent_name, debug_source]
