class_name InstantiateBinding
extends Binding

const EMPTY := &"__empty__"

## The scene to be used when instantiating items on this list
@export var item_scene: PackedScene

@export_category("Item Scenes By Key")

## The expression to use as key for selecting item scenes from the dictionary.
@export var item_scene_key_expression: StringName

## A dictionary mapping keys to item scenes for instantiation.
@export var item_scenes_by_key: Dictionary[StringName, PackedScene] = {}

var _child: Node
var _current_scene_key := EMPTY


func _refresh_binding() -> void:
	if _bound_data_source == null:
		if _child:
			_child.queue_free()
			_child = null
			_current_scene_key = EMPTY
		return

	var parent := get_parent()

	Log.debug(&"InstantiateBinding", "%s: Refreshing with value: %s=%s" % [self, debug_source, bound_value])

	var scene_key := &""

	# If we have a key expression, use it to select the scene
	if item_scene_key_expression:
		scene_key = StringName(str(BindingUtils.evaluate_expression(_bound_data_source, item_scene_key_expression)))

	# Only reinstantiate if the scene key has changed
	if scene_key != _current_scene_key:
		if _child:
			_child.queue_free()
			_child = null

		var scene := item_scene

		if scene_key in item_scenes_by_key:
			scene = item_scenes_by_key[scene_key]

		if scene:
			_current_scene_key = scene_key
			_child = scene.instantiate()
			parent.add_child(_child)

	# Always update the binding context on the child
	if _child:
		BindingContext.set_data_source(_child, bound_value)
