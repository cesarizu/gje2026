class_name DataSourceBinding
extends Binding

## Binds the current node's BindingContext data source from the parent binding context.
## The evaluated expression value is set as the data_source on the same node's BindingContext.


func _ready() -> void:
	# Walk up from the parent node so we skip the current node's own BindingContext
	# and find the ancestor context to read the value from.
	_context = BindingContext.get_parent_context(get_parent())


func _refresh_binding() -> void:
	if not _bound_data_source:
		return

	var self_context := BindingContext.get_self_context(get_parent())
	if not self_context:
		return

	Log.debug(&"DataSourceBinding", "%s: Setting data source to %s=%s" % [self, debug_source, bound_value])

	self_context.data_source = bound_value


func _to_string() -> String:
	var parent_name := get_parent().name if get_parent() else "null"
	return "DataSourceBinding(%s=%s)" % [parent_name, debug_source]
