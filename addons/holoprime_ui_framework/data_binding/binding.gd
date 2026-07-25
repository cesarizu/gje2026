@abstract
class_name Binding
extends Node

## This class represents a base binding for data contexts in the UI framework that connects a data property with an UI element.
## Automatically finds the closest BindingContext ancestor and connects to its data_context_changed signal.

## Expression to evaluate with the data source as context.
## Can be a simple property access (e.g., "health") or any valid GDScript expression.
@export var expression: StringName:
	set(value):
		expression = value
		_evaluate_bound_value()

## A debug string representing the source of this binding.
var debug_source: String:
	get:
		return "%s" % [expression if expression else "self"]

## The BindingContext this binding is associated with.
var _context: BindingContext:
	set(value):
		if _context:
			if _context.data_source_changed.is_connected(_on_context_data_source_changed):
				_context.data_source_changed.disconnect(_on_context_data_source_changed)

			if _context.data_source_property_changed.is_connected(_on_context_data_source_property_changed):
				_context.data_source_property_changed.disconnect(_on_context_data_source_property_changed)

		Log.debug(&"Binding", "%s: Context set to %s" % [self, value])

		_context = value

		if _context:
			_context.data_source_changed.connect(_on_context_data_source_changed)
			_context.data_source_property_changed.connect(_on_context_data_source_property_changed)
			_on_context_data_source_changed()

## The data source currently bound to this binding.
var _bound_data_source: Variant:
	set(value):
		Log.debug(&"Binding", "%s: Data source set to %s" % [self, value])
		_bound_data_source = value
		_evaluate_bound_value()

## The cached evaluated value from the expression.
var bound_value: Variant


func _evaluate_bound_value() -> void:
	if not _bound_data_source:
		bound_value = null
	else:
		bound_value = BindingUtils.evaluate_expression(_bound_data_source, expression)

	_refresh_binding()


func _ready() -> void:
	_context = BindingContext.get_parent_context(self)


func _exit_tree() -> void:
	_context = null


func _on_context_data_source_changed(data_source: Variant = null) -> void:
	_bound_data_source = data_source


func _on_context_data_source_property_changed(_data_source: Variant, property: StringName, _value: Variant) -> void:
	# For simple expressions (single property access), only evaluate if the property matches
	if expression and not ("." in expression or "(" in expression):
		if property != expression:
			return

	# For complex expressions or when property matches, evaluate
	_evaluate_bound_value()


@abstract
func _refresh_binding() -> void
