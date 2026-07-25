## Holds at most one active tween for an owner node.
##
## [TweenHandler] is useful when the same transition can be started repeatedly and
## only the latest call should keep running. Calling [method create_tween] kills the
## previously created [InterruptibleTween], if any, and returns a new tween-like
## node that can be configured with a small subset of the regular [Tween] API.
##
## Unlike a plain [Tween], the returned [InterruptibleTween] resolves
## [signal InterruptibleTween.finished] with [code]true[/code] when it completes
## normally and [code]false[/code] when it gets replaced or killed. That makes it
## safe to await without stale continuations pretending they finished successfully.
##
## Use a plain [Tween] for fire-and-forget animation. Use [TweenHandler] when a
## newer transition should replace the previous one cleanly.
##
## Migration example:
## [codeblock]
## # Before
## func fade_to(volume: float, duration: float) -> void:
##     var tween := create_tween()
##     tween.tween_property(self, ^"volume_linear", volume, duration)
##     await tween.finished
##
## # After
## var _fade_tween_handler := TweenHandler.new(self)
##
## func fade_to(volume: float, duration: float) -> bool:
##     var tween := _fade_tween_handler.create_tween()
##     tween.tween_property(self, ^"volume_linear", volume, duration)
##     return await tween.finished
## [/codeblock]
##
## To migrate an existing replaceable [Tween]:
##
## Keep one [TweenHandler] field per tween slot, like [code]_fade_tween_handler[/code].
##
## Replace [method Node.create_tween] with [method create_tween].
##
## Use [method InterruptibleTween.tween_property] or [method InterruptibleTween.tween_method] to configure it.
##
## Use [method InterruptibleTween.parallel] when you need parallel tweeners.
##
## Use the [code]bool[/code] from [code]await tween.finished[/code] when interruption matters.
class_name TweenHandler
extends RefCounted

var _owner: Node
var _tween: InterruptibleTween


func _init(owner_: Node) -> void:
	_owner = owner_


## Creates a new [InterruptibleTween] for the owner node.
##
## If a previous tween exists in this handler, it is killed first and its
## awaiters resolve with [code]false[/code].
func create_tween() -> InterruptibleTween:
	assert(_owner != null, "TweenHandler needs an owner Node.")

	kill()

	_tween = InterruptibleTween.new(_owner.create_tween())
	_tween.name = &"InterruptibleTween"
	_tween.finished.connect(_on_tween_finished.bind(_tween), CONNECT_ONE_SHOT)

	_owner.add_child(_tween, false, Node.INTERNAL_MODE_BACK)

	return _tween


## Kills the current tween, if any, and resolves its awaiters with [code]false[/code].
func kill() -> void:
	if _tween:
		var tween := _tween
		_tween = null
		tween.kill()


func is_running() -> bool:
	return _tween != null


func _on_tween_finished(_completed: bool, tween: InterruptibleTween) -> void:
	if tween == _tween:
		_tween = null
