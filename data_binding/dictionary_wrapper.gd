class_name DictionaryWrapper
extends Object

## Wrapper for Dictionaries to allow them to be used as object data sources in BindingContexts.

var _value: Dictionary


static func wrap(value: Variant) -> Variant:
	return DictionaryWrapper.new(value) if value is Dictionary else value


static func unwrap(value: Variant) -> Variant:
	return value.to_dictionary() if value is DictionaryWrapper else value


func _init(dictionary: Dictionary) -> void:
	_value = dictionary


func _get_property_list() -> Array[Dictionary]:
	var property_list: Array[Dictionary] = []

	var properties: Array = _value.keys()
	for prop in properties:
		var val = _value[prop]
		property_list.append({ "name": prop, "class_name": val.get_class_name() if val is Object else "", "type": typeof(val) })

	return property_list


func _get(property: StringName) -> Variant:
	if property in _value:
		return _value.get(property)

	return null


func to_dictionary() -> Dictionary:
	return _value


func _to_string() -> String:
	return str(_value)
