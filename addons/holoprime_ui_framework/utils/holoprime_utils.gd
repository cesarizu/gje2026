class_name HoloprimeUtils


static func find_by_class(root: Node, type: Variant) -> Array:
	var res := []
	_find_by_class(root, type, res)
	return res


static func _find_by_class(node: Node, type: Variant, result: Array) -> void:
	if is_instance_of(node, type):
		result.push_back(node)

	for child in node.get_children():
		_find_by_class(child, type, result)
