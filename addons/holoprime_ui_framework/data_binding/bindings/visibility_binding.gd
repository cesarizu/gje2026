class_name VisibilityBinding
extends Binding


func _refresh_binding() -> void:
	if _bound_data_source == null:
		return

	var value := bound_value
	var parent := get_parent()

	Log.debug(&"VisibilityBinding", "%s: Refreshing with value: %s=%s" % [self, debug_source, value])

	if parent is CanvasItem:
		var visible := bool(value)
		Log.debug(&"Binding", "%s: Setting visibility to %s" % [self, visible])
		parent.visible = visible


func _to_string() -> String:
	var parent_name := get_parent().name if get_parent() else "null"

	return "VisibilityBinding(%s=%s)" % [parent_name, debug_source]
