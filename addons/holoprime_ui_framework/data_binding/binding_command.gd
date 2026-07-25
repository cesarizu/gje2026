class_name BindingCommand
extends Node

## This will execute the command on the associated binding context. It will look for a context starting from the parent node.
## This is used to allow PackedScenes to have the equivalent of signals sent to their parent context.

## The name of the command to execute.
@export var command_name: StringName

## Whether to propagate the command to the parent context if not handled.
## A command can be marked as handled by calling BindingContext.get_self_context(self).set_command_as_handled().
@export var propagate := true

@onready var _context := BindingContext.get_parent_context(get_parent())


func _ready() -> void:
	var parent := get_parent()
	if parent.has_signal(&"pressed"):
		parent.pressed.connect(execute.bind(parent))


func execute(source: Node, ...params) -> void:
	if not _context:
		Log.warn(&"BindingCommand", "Cannot execute '%s', no parent binding context found for %s" % [command_name, self])
		return

	var source_context := BindingContext.get_self_context(source)
	_context.push_command.bindv(params).call(command_name, source_context, propagate)
