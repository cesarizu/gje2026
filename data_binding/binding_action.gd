class_name BindingAction
extends Node

## This will execute the action on the associated binding context. It will look for a context starting from the parent node.
## This is used to allow PackedScenes to have the equivalent of signals sent to their parent context.

@export var action_name: String

@onready var _context := BindingContext.get_parent_context(get_parent())


func execute(source: Node, ...params) -> void:
	var source_context := BindingContext.get_self_context(source)
	_context.push_action.bindv(params).call(action_name, source_context)
