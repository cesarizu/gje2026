class_name ViewModel
extends Resource

## Base class for view models. Implements a simple property change notification mechanism.

signal property_changed(property: StringName, value: Variant)


func set(property: StringName, value: Variant) -> void:
	super.set(property, value)
	notify_property_changed(property)


func notify_property_changed(property: StringName) -> void:
	property_changed.emit(property, get(property))
