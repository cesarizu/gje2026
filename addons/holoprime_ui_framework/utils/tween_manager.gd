## Reuses interruptible tween slots by tag on an owner node.
##
## [TweenManager] is a convenience wrapper around [TweenHandler] for cases where
## a dedicated handler field would add noise. It stores one handler per
## [param owner] and [param tag] pair in the owner's metadata.
##
## Calling [method create_tween] with the same tag kills the previously running
## tween for that slot and returns a fresh [InterruptibleTween].
##
## Prefer stable tags such as a method name or a group name:
## [codeblock]
## func _start_photo_ik_tween(target_interpolation: float, duration: float) -> InterruptibleTween:
##     var tween := TweenManager.create_tween(self, &"_start_photo_ik_tween")
##     tween.tween_property(photo_skeleton_ik_3d, ^"interpolation", target_interpolation, duration)
##     return tween
## [/codeblock]
##
## Use [method kill] to cancel a tagged tween from somewhere else, or
## [method is_running] to check whether that tween slot is still active.
class_name TweenManager
extends RefCounted

const META_TWEEN_HANDLERS := &"_holoprime_tween_handlers"


## Creates or replaces the tween stored for [param tag] on [param owner].
##
## If another tween is already running for this owner/tag pair, it is killed
## first and its awaiters resolve with [code]false[/code].
static func create_tween(owner: Node, tag: StringName) -> InterruptibleTween:
	return _get_handler(owner, tag).create_tween()


## Kills the tween stored for [param tag] on [param owner], if any.
static func kill(owner: Node, tag: StringName) -> void:
	var handler := _find_handler(owner, tag)
	if handler:
		handler.kill()


## Returns [code]true[/code] when the tween stored for [param tag] on
## [param owner] is currently active.
static func is_running(owner: Node, tag: StringName) -> bool:
	var handler := _find_handler(owner, tag)
	return handler != null and handler.is_running()


static func _find_handler(owner: Node, tag: StringName) -> TweenHandler:
	if not owner or not owner.has_meta(META_TWEEN_HANDLERS):
		return null

	var handlers: Dictionary = owner.get_meta(META_TWEEN_HANDLERS)
	return handlers.get(tag)


static func _get_handler(owner: Node, tag: StringName) -> TweenHandler:
	assert(owner != null, "TweenManager needs an owner Node.")

	if not owner.has_meta(META_TWEEN_HANDLERS):
		owner.set_meta(META_TWEEN_HANDLERS, {})

	var handlers: Dictionary = owner.get_meta(META_TWEEN_HANDLERS)
	var handler: TweenHandler = handlers.get(tag)

	if not handler:
		handler = TweenHandler.new(owner)
		handlers[tag] = handler

	return handler
