class_name ShortcutTexture2D
extends Texture2D

## A dynamic Texture2D that automatically displays the appropriate icon for a shortcut's input events.
##
## This texture listens to input method changes (keyboard/mouse vs controller) and updates
## its displayed icon accordingly by querying ControllerIcons. It also reacts to changes
## in the assigned Shortcut resource.
##
## Usage: Assign a Shortcut resource to the [member shortcut] property. The texture will
## automatically display the first valid icon found for the shortcut's events based on
## the current input method.

## The shortcut whose icon should be displayed.
##
## When set, the texture connects to the shortcut's [signal Shortcut.changed] signal
## to update automatically when the shortcut is modified. The texture will display
## the icon for the first input event in the shortcut that has a valid icon.
@export var shortcut: Shortcut:
	set(value):
		if shortcut == value:
			return

		if shortcut:
			if shortcut.changed.is_connected(_update_texture):
				shortcut.changed.disconnect(_update_texture)

		shortcut = value

		if shortcut:
			if not shortcut.changed.is_connected(_update_texture):
				shortcut.changed.connect(_update_texture)

		_update_texture()

## Player index used for icon lookup. Set by the owning node at creation time. Defaults to
## AUTO (no multiplayer context) so standalone textures follow the global last-used device.
var player_index: int = MultiplayerContext.AUTO_PLAYER_INDEX

var _current_texture: Texture2D


func _init() -> void:
	if not Engine.is_editor_hint():
		InputManager.input_method_changed.connect(_on_input_method_changed)

	_update_texture()


func _on_input_method_changed(_new_input_method: InputManager.InputMethod, changed_player_index: int) -> void:
	if changed_player_index == player_index:
		_update_texture()


func _update_texture() -> void:
	var new_texture: Texture2D = null

	if shortcut:
		for event: InputEvent in shortcut.events:
			var icon := ControllerIcons.get_icon(event, player_index, resource_name)
			if icon:
				new_texture = icon
				break

	if _current_texture != new_texture:
		_current_texture = new_texture
		emit_changed()


#region Texture2DOverrides

func _get_width() -> int:
	return _current_texture.get_width() if _current_texture else 0


func _get_height() -> int:
	return _current_texture.get_height() if _current_texture else 0


func _has_alpha() -> bool:
	return _current_texture.has_alpha() if _current_texture else false


func _draw(to_canvas_item: RID, pos: Vector2, color: Color, transpose: bool) -> void:
	if _current_texture:
		_current_texture.draw(to_canvas_item, pos, color, transpose)


func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, color: Color, transpose: bool) -> void:
	if _current_texture:
		_current_texture.draw_rect(to_canvas_item, rect, tile, color, transpose)


func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, color: Color, transpose: bool, clip_uv: bool) -> void:
	if _current_texture:
		_current_texture.draw_rect_region(to_canvas_item, rect, src_rect, color, transpose, clip_uv)


func _is_pixel_opaque(x: int, y: int) -> bool:
	return _current_texture.is_pixel_opaque(x, y) if _current_texture else false

#endregion
