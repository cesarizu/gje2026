## Tween-like node that wraps a regular [Tween] and reports interruption.
##
## Unlike a plain [Tween], [signal finished] emits [code]true[/code] when the
## tween completes normally and [code]false[/code] when it gets killed or
## replaced. That makes it safe to await from stateful gameplay code.
class_name InterruptibleTween
extends Node


## Emitted when the tween completes or gets interrupted.
## @param completed [code]true[/code] on normal completion and [code]false[/code]
## when the tween is killed or replaced by a newer one.
signal finished(completed: bool)

var _completed := false
var _resolved := false
var _tween: Tween


func _init(tween: Tween):
	_tween = tween
	_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)


## Equivalent to [method Tween.tween_property] on the wrapped tween.
func tween_property(object: Object, property: NodePath, final_val: Variant, duration: float) -> PropertyTweener:
	return _require_tween().tween_property(object, property, final_val, duration)


## Equivalent to [method Tween.tween_method] on the wrapped tween.
func tween_method(method: Callable, from: Variant, to: Variant, duration: float) -> MethodTweener:
	return _require_tween().tween_method(method, from, to, duration)


## Equivalent to [method Tween.tween_callback] on the wrapped tween.
func tween_callback(callback: Callable) -> CallbackTweener:
	return _require_tween().tween_callback(callback)


## Equivalent to [method Tween.parallel] on the wrapped tween.
func parallel() -> Tween:
	return _require_tween().parallel()


## Equivalent to [method Tween.set_parallel] on the wrapped tween.
func set_parallel(enabled := true) -> InterruptibleTween:
	_require_tween().set_parallel(enabled)
	return self


## Equivalent to [method Tween.set_ease] on the wrapped tween.
func set_ease(ease: Tween.EaseType) -> InterruptibleTween:
	_require_tween().set_ease(ease)
	return self


## Equivalent to [method Tween.set_trans] on the wrapped tween.
func set_trans(trans: Tween.TransitionType) -> InterruptibleTween:
	_require_tween().set_trans(trans)
	return self


func is_running() -> bool:
	return _tween != null and not _resolved


## Kills the wrapped tween and resolves [signal finished] with [code]false[/code].
func kill() -> void:
	if _tween:
		_tween.kill()
		_tween = null

	_resolve(false)


func _resolve(completed_: bool) -> void:
	if _resolved:
		return

	_resolved = true
	_completed = completed_
	_tween = null
	finished.emit(_completed)
	queue_free()


func _exit_tree() -> void:
	if _resolved:
		return

	_resolved = true
	_completed = false
	finished.emit(false)


func _on_tween_finished() -> void:
	_resolve(true)


func _require_tween() -> Tween:
	assert(_tween != null, "TweenHandler.create_tween() must be called before configuring tweeners.")
	return _tween
