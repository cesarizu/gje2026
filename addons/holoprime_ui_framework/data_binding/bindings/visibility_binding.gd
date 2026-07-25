class_name VisibilityBinding
extends Binding

enum AnimationMode {
	NONE,
	TWEEN,
	ANIMATION_PLAYER,
}

@export var animation_mode: AnimationMode = AnimationMode.NONE

@export_group("Tween")
@export var fade_duration: float = 0.3
@export var displacement_in: Vector2 = Vector2.ZERO
@export var displacement_out: Vector2 = Vector2.ZERO

@export_group("Animation Player")
@export var animation_player: AnimationPlayer
@export var animation_in: StringName = &""
@export var animation_out: StringName = &""

var _visible: bool = false
var _original_position: Vector2
var _tween: Tween
var _hide_pending: bool = false


func _ready() -> void:
	var parent := get_parent()

	_visible = parent.visible

	super()


func _is_parent_visible() -> bool:
	return true


func _refresh_binding() -> void:
	if _bound_data_source == null:
		return

	var value := bound_value
	var visible := bound_value != null and bool(bound_value)
	var parent := get_parent()

	Log.debug(&"VisibilityBinding", "%s: Refreshing with visible: %s=%s" % [self, debug_source, value])

	if parent is CanvasItem and visible != _visible:
		_visible = visible
		Log.debug(&"Binding", "%s: Setting visibility to %s" % [self, visible])
		_apply_visibility(parent, visible)


func _apply_visibility(parent: CanvasItem, visible: bool) -> void:
	match animation_mode:
		AnimationMode.NONE:
			parent.visible = visible

		AnimationMode.TWEEN:
			_apply_tween(parent, visible)

		AnimationMode.ANIMATION_PLAYER:
			_apply_animation_player(parent, visible)


func _apply_tween(parent: CanvasItem, visible: bool) -> void:
	if _tween:
		_tween.kill()
	else:
		_original_position = parent.position

	if visible:
		parent.visible = true

		_tween = create_tween().set_parallel(true)

		parent.modulate.a = 0.0
		_tween.tween_property(parent, ^"modulate:a", 1.0, fade_duration)

		if parent is Control and displacement_in != Vector2.ZERO:
			parent.position = _original_position + displacement_in
			_tween.tween_property(parent, ^"position", _original_position, fade_duration)

	else:
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(parent, ^"modulate:a", 0.0, fade_duration)

		if parent is Control and displacement_out != Vector2.ZERO:
			_tween.tween_property(parent, ^"position", _original_position + displacement_out, fade_duration)

		await _tween.finished

		parent.visible = false
		parent.modulate.a = 1.0

		if parent is Control and displacement_out != Vector2.ZERO:
			parent.position = _original_position


func _apply_animation_player(parent: CanvasItem, visible: bool) -> void:
	if not is_instance_valid(animation_player):
		parent.visible = visible
		return

	if visible:
		parent.visible = true

		if animation_in and animation_player.has_animation(animation_in):
			animation_player.play(animation_in)

	else:
		if animation_out and animation_player.has_animation(animation_out):
			if animation_player.is_playing():
				await animation_player.animation_finished

			animation_player.play(animation_out)

			await animation_player.animation_finished

		parent.visible = false


func _to_string() -> String:
	var parent_name := get_parent().name if get_parent() else "null"

	return "VisibilityBinding(%s=%s)" % [parent_name, debug_source]
