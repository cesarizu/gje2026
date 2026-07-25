class_name ValueBinding
extends Binding

## Binds a data property to a UI element's property.
## Supports template strings with expressions evaluated inside "{" and "}" brackets.

## Template string with expressions inside "{" and "}" brackets.
## Expressions are evaluated using the bound data as context.
## Examples: "Health: {health} / {max_health}", "Score: {value * 100}", "Level {level + 1}"
@export_multiline var template: String:
	set(value):
		template = value
		_refresh_binding()

## The target property path on the UI element to bind to. Uses a default property if not set.
@export var target_property_path: StringName:
	set(value):
		target_property_path = value
		_refresh_binding()


func _refresh_binding() -> void:
	if _bound_data_source == null:
		return

	var value := bound_value
	var parent := get_parent()

	# Apply template if specified
	if template:
		value = _apply_template(template, value)

	Log.debug(&"ValueBinding", "%s: Refreshing with value: %s=%s" % [self, debug_source, value])

	BindingUtils.bind_value(parent, value, target_property_path)


## Evaluates expressions inside "{" and "}" brackets using the data as context.
func _apply_template(template_str: String, data: Variant) -> String:
	var regex := RegEx.new()
	regex.compile(r"\{([^}]+)\}")

	var result := template_str

	for match in regex.search_all(template_str):
		var placeholder := match.get_string()
		var expression_str := match.get_string(1)
		var resolved_value := BindingUtils.evaluate_expression(data, expression_str)

		Log.debug(&"ValueBinding", "_apply_template: Resolved '{%s}' → '%s'" % [expression_str, resolved_value])
		result = result.replace(placeholder, str(resolved_value))

	return result


func _to_string() -> String:
	var parent_name := get_parent().name if get_parent() else "null"

	return "ValueBinding(%s=%s)" % [parent_name, debug_source]
