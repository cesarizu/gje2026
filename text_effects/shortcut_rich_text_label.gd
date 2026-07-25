class_name ShortcutRichTextLabel
extends RichTextLabel

## Optional: force a consistent icon height (0 = use theme font size-ish default).
@export var icon_height: int = 0:
	set(value):
		icon_height = value
		_rebuild()

var _source_text := ""
var _icon_textures: Array[ShortcutTexture2D] = []
var _re_input := RegEx.new()

## Resolved fresh from the MultiplayerContext ancestor; the binding that drives it may set
## the context's player_index after this node is ready, so it must not be cached.
var _player_index: int:
	get:
		return MultiplayerContext.get_player_index(self)


func _enter_tree() -> void:
	_source_text = text
	bbcode_enabled = false

	_re_input.compile("\\[input\\]([A-Za-z0-9_\\-:]+)\\[/input\\]")
	_rebuild()


func _ready() -> void:
	InputManager.input_method_changed.connect(_on_input_method_changed)


func _exit_tree() -> void:
	InputManager.input_method_changed.disconnect(_on_input_method_changed)


func set_text(text: String) -> void:
	_source_text = text
	_rebuild()


func _on_input_method_changed(_new_input_method: InputManager.InputMethod, player_index: int) -> void:
	if player_index == _player_index:
		# Keep the inline textures in sync in case the context's player_index changed after
		# they were created, then redraw.
		for tex in _icon_textures:
			tex.player_index = _player_index
		queue_redraw()


func _rebuild() -> void:
	clear()
	_icon_textures.clear()

	if _source_text.is_empty():
		return

	var last_end := 0
	for m: RegExMatch in _re_input.search_all(_source_text):
		var start := m.get_start(0)
		var end := m.get_end(0)

		if start > last_end:
			# BUG this won't close bbcode tags, see docs
			append_text(_source_text.substr(last_end, start - last_end))

		_append_action_icon(StringName(m.get_string(1)))
		last_end = end

	if last_end < _source_text.length():
		# BUG this won't close bbcode tags, see docs
		append_text(_source_text.substr(last_end))


func _append_action_icon(action_name: StringName) -> void:
	var shortcut := Shortcut.new()

	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	shortcut.events.append(event)

	var tex := ShortcutTexture2D.new()
	tex.resource_name = "action:%s" % String(action_name)
	tex.player_index = _player_index
	tex.shortcut = shortcut
	tex.changed.connect(queue_redraw)

	_icon_textures.append(tex)

	var h := icon_height
	if h <= 0:
		var fs := get_theme_font_size("normal_font_size")
		h = fs if fs > 0 else 16

	if tex.get_width() > 0:
		add_image(tex, 0, h, Color.WHITE, INLINE_ALIGNMENT_CENTER)
