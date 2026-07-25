class_name BindingUtils

## This class provides utility functions for data binding in the UI framework.


## Returns true if the node is bindable (has a BindingContext or is a supported UI type).
static func is_bindable(node: Node, property_path: StringName) -> bool:
	if node is BindingContext or node is Binding or node is BindingCommand:
		return false

	if property_path != &"" or BindingContext.has_self_context(node):
		return true

	return node is Container or node is BaseButton or node is Label or \
		node is RichTextLabel or node is TextureRect


## Sets the value on the node based on the node type and value type.
static func bind_value(node: Node, value: Variant, target_property := "") -> void:
	if target_property:
		node.set(target_property, value)

	elif node is BaseButton:
		if value is Texture2D:
			node.icon = value
		elif value is String:
			set_text(node, value)

	elif node is Label:
		set_text(node, value)

	elif node is RichTextLabel:
		set_text(node, value)

	elif node is TextureRect:
		if value is Texture2D:
			node.texture = value


static func set_text(node: Node, value: Variant) -> void:
	if node.has_method("set_text"):
		node.call("set_text", str(value))
	else:
		node.text = str(value)


## Evaluates an expression on the given data object using GDScript Expression.
## Can be a simple property access (e.g., "health") or any valid GDScript expression.
## Returns null if the expression fails to parse or execute.
static func evaluate_expression(data: Variant, expression: String) -> Variant:
	if not expression:
		return data

	var ex := Expression.new()
	var parse_error := ex.parse(expression)

	if parse_error != OK:
		Log.warn(&"BindingUtils", "Failed to parse expression '%s': %s" % [expression, ex.get_error_text()])
		return null

	var result := ex.execute([], DictionaryWrapper.wrap(data)) if data else null

	if ex.has_execute_failed():
		Log.warn(&"BindingUtils", "Failed to execute expression '%s' on '%s': %s" % [expression, data, ex.get_error_text()])
		return null

	return DictionaryWrapper.unwrap(result)


#region Container Binding Utils

## Updates container items by instantiating/freeing as needed and setting data sources.
## Returns an array of the instantiated/bound children nodes.
static func setup_children_nodes(parent: Node, list: Array, property_path: StringName, instantiate: Callable, existing_children: Array[Node] = [], insert_after_node: Node = null) -> Array[Node]:
	var bindable_node_count := existing_children.size()

	Log.debug(&"BindingUtils", "setup_children_nodes: Container '%s' has %d bindable nodes, needs %d items" % [parent.name, bindable_node_count, list.size()])

	if not parent.is_node_ready():
		await parent.ready

	# Instantiate new items if needed.
	var last_node := insert_after_node if existing_children.is_empty() else existing_children[-1]
	for index in range(bindable_node_count, list.size()):
		var item_instance := instantiate.call(list[index])
		if last_node:
			last_node.add_sibling(item_instance)
			last_node = item_instance
		else:
			parent.add_child(item_instance)
		existing_children.append(item_instance)
		Log.debug(&"BindingUtils", "setup_children_nodes: Instantiated item %d" % index)

	# Queue free excess items.
	for child_index in range(list.size(), existing_children.size()):
		Log.debug(&"BindingUtils", "setup_children_nodes: Queueing excess item at index %d" % child_index)
		existing_children[child_index].queue_free()

	# Trim the array to the list size
	existing_children.resize(list.size())

	# Setup data sources for all items.
	return set_children_data_sources_on_nodes(existing_children, list, property_path)


## Sets data sources on specific nodes.
## Returns an array of the bound children nodes.
static func set_children_data_sources_on_nodes(nodes: Array[Node], list: Array, property_path: StringName) -> Array[Node]:
	var bound_children: Array[Node] = []

	for data_index in range(min(nodes.size(), list.size())):
		var child := nodes[data_index]
		Log.debug(&"BindingUtils", "set_children_data_sources_on_nodes: Binding child '%s' to data index %d (%s)" % [child.name, data_index, property_path])

		if is_bindable(child, property_path):
			if property_path != &"":
				child.set(property_path, list[data_index])
			elif not BindingContext.set_data_source(child, list[data_index]):
				bind_value(child, list[data_index])

			bound_children.append(child)

	return bound_children


## Sets data sources on all children items that are bindable.
## Returns an array of the bound children nodes.
static func set_children_data_sources(parent: Node, list: Array, property_path: StringName) -> Array[Node]:
	var list_items := parent.get_children()
	var data_index := 0
	var bound_children: Array[Node] = []

	for child in list_items:
		if data_index >= list.size():
			break

		Log.debug(&"BindingUtils", "set_children_data_sources: Binding child '%s' to data index %d (%s)" % [child.name, data_index, property_path])


		if is_bindable(child, property_path):
			if property_path != &"":
				child.set(property_path, list[data_index])
			elif not BindingContext.set_data_source(child, list[data_index]):
				bind_value(child, list[data_index])

			bound_children.append(child)
			data_index += 1

	return bound_children


static func get_array_from_variant(value: Variant) -> Array:
	if value is Array:
		return value
	elif value is Dictionary:
		return value.values()
	elif value != null:
		return [value]
	else:
		return []

#endregion
