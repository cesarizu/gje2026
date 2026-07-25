class_name BindingContext
extends Node

## This class represents a data context for data binding in the UI framework.
## Automatically registers itself in the 'DataBindingContexts' group on enter tree
## so that child Binding nodes can discover and connect to it.

const GROUP_NAME := &"BindingContexts"
const BINDING_CONTEXT_META_NAME := &"BindingContext"

signal data_source_changed(data_source: Variant)
signal data_source_property_changed(data_source: Variant, property: StringName, value: Variant)

signal command_executed(command_name: StringName, binding_context: BindingContext, params: Array)

var _is_command_handled := false

## The data source currently bound to this context.
var data_source: Variant:
	set(value):
		# Disconnect previous data source listeners
		if data_source is ViewModel and data_source.property_changed.is_connected(_on_data_source_property_changed):
			data_source.property_changed.disconnect(_on_data_source_property_changed)

		if data_source is Resource and data_source.changed.is_connected(_on_data_source_changed):
			data_source.changed.disconnect(_on_data_source_changed)

		data_source = value

		# Listen to data source changes
		if data_source is ViewModel:
			data_source.property_changed.connect(_on_data_source_property_changed)

		if data_source is Resource:
			data_source.changed.connect(_on_data_source_changed)

		Log.debug(&"BindingContext", "%s: Changed datasource to %s" % [self, value])
		data_source_changed.emit(data_source)

#region Static Methods

## Sets the data source for the data context of the given node.
static func set_data_source(node: Node, data_source: Variant) -> bool:
	if has_self_context(node):
		get_self_context(node).data_source = data_source
		return true
	else:
		Log.warn(&"BindingContext", "Cannot set data source, no BindingContext found for node '%s'" % [node])
		return false


## Retrieves the BindingContext for the given node.
## to find the nearest parent in the GROUP_NAME group and returning its stored context.
static func has_self_context(node: Node) -> bool:
	return node and node.is_in_group(GROUP_NAME) and node.has_meta(BINDING_CONTEXT_META_NAME)


## Retrieves the BindingContext for the given node.
## to find the nearest parent in the GROUP_NAME group and returning its stored context.
static func get_self_context(node: Node) -> BindingContext:
	if node.is_in_group(GROUP_NAME) and node.has_meta(BINDING_CONTEXT_META_NAME):
		return node.get_meta(BINDING_CONTEXT_META_NAME)
	return null


## Retrieves the BindingContext for the given node by walking up the tree
## to find the nearest parent in the GROUP_NAME group and returning its stored context.
static func get_parent_context(node: Node) -> BindingContext:
	var current := node.get_parent()
	while current:
		if current.is_in_group(GROUP_NAME):
			if current.has_meta(BINDING_CONTEXT_META_NAME):
				return current.get_meta(BINDING_CONTEXT_META_NAME)
		current = current.get_parent()
	return null

#endregion

func _enter_tree() -> void:
	var parent := get_parent()

	Log.debug(&"BindingContext", "%s: Registering in parent" % self)

	parent.add_to_group(GROUP_NAME)
	parent.set_meta(BINDING_CONTEXT_META_NAME, self)


func _exit_tree() -> void:
	var parent := get_parent()

	Log.debug(&"BindingContext", "%s: Unregistering from parent '%s'" % [self, parent.name])

	parent.remove_from_group(GROUP_NAME)
	parent.remove_meta(BINDING_CONTEXT_META_NAME)


func _to_string() -> String:
	var parent_name := get_parent().name if get_parent() else "null"
	return "BindingContext[%s]" % parent_name


## Pushes a command into this context. This will be broadcasted with a signal.
func push_command(command_name: StringName, binding_context: BindingContext, propagate := false, ...params) -> void:
	_is_command_handled = false
	command_executed.emit(command_name, binding_context, params)

	if propagate and not _is_command_handled:
		var parent_context := get_parent_context(get_parent())
		if parent_context:
			parent_context.push_command.bindv(params).call(command_name, binding_context, propagate)


## Marks the command as handled, so that it won't be propagated further.
func set_command_as_handled() -> void:
	_is_command_handled = true


## Called when a property in the data source changes.
func _on_data_source_changed() -> void:
	data_source_changed.emit(data_source)


## Called when a property in the data source changes.
func _on_data_source_property_changed(property: StringName, value: Variant) -> void:
	data_source_property_changed.emit(data_source, property, value)
