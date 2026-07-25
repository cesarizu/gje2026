class_name Menu
extends CanvasLayer

## Base class for UI menus.
##
## Implement [method _setup_menu] with any parameters to receive those parameters prior to pushing the menu to the stack.
## Any other overriden function must call the super function to maintain correct functionality.

## Indicates a list of controls that can have the default focus.
@export var default_focus: Array[Control] = []

## Whether to save the last focused element when loosing focus or not.
@export var save_last_focused := true

## Indicates that the menu should relase the focus when using keyboard and mouse.
@export var release_focus_on_keyboard := true

## If true, the menu will be hiddeng when focus out is called
@export var hide_on_focus_out := true

## The parent menu of this menu, if any. This is the menu immediately before this menu in the stack.
var parent: Menu

## Indicates if this menu currently has the focus, i.e. is the menu in the top of the stack.
var has_focus: bool

## Indicates if this menu is popped of the stack.
var is_popped: bool

var _menu_stack: MenuStack

var _last_focus: Control

var _ready_called: bool

#region Lifecycle


func _ready() -> void:
	_ready_called = true

	_menu_stack = get_parent() as MenuStack

	if not _menu_stack and MenuStack.main_stack:
		Log.info(&"Menu", "Menu is not in any stack, moving it to the main stack")
		await get_tree().process_frame
		_menu_stack = MenuStack.main_stack
		reparent(_menu_stack)
		_menu_stack.push(self)

	if _menu_stack:
		_menu_stack.try_set_as_top.call_deferred(self)
	else:
		Log.warn(&"Menu", "Menu is not in any stack!")

	InputManager.input_method_changed.connect(_on_input_method_changed)
	_on_input_method_changed(InputManager.current_input_method)

	update_focus()


func _shortcut_input(event: InputEvent) -> void:
	if not has_focus:
		return

	if event.is_action_pressed("menu_back"):
		if not _menu_stack or (_menu_stack.size() == 1 and _menu_stack.top == self):
			return

		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _to_string() -> String:
	return name


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Handle Android back button
			_on_back_pressed()


#endregion

#region Public methods


## Tries to update the focus in the menu. If there's no focused control, it will try to focus the default control.
func update_focus() -> void:
	if not is_inside_tree():
		return

	await get_tree().process_frame

	if not is_inside_tree():
		return

	var viewport := get_viewport()

	if not viewport:
		return

	var focused: Control = viewport.gui_get_focus_owner()

	if not focused:
		var control: Control = _get_default_focus()
		if control:
			control.grab_focus()


## Removes this menu from the current stack.
func pop_self() -> void:
	if not _menu_stack:
		if get_tree().current_scene == self:
			get_tree().quit()
		else:
			Log.warn(&"Menu", "Menu not on a stack: %s" % self)
	elif _menu_stack.is_on_top(self):
		_menu_stack.pop_top()
	else:
		Log.warn(&"Menu", "Menu not on top: %s stack=[%s]" % [self, ",".join(_menu_stack._stack)])
		_menu_stack.pop(self)


#endregion

#region Private methods


func _on_input_method_changed(new_input_method: InputManager.InputMethod) -> void:
	if not has_focus:
		return

	if new_input_method == InputManager.InputMethod.GAMEPAD:
		update_focus()
	elif release_focus_on_keyboard:
		get_viewport().gui_release_focus()


func save_last_focus() -> void:
	if save_last_focused and is_inside_tree():
		_last_focus = get_viewport().gui_get_focus_owner()
		get_viewport().gui_release_focus()


#endregion

#region Overridable methods


## Defines the functionality when the menu_back action is pressed.
func _on_back_pressed() -> void:
	if not has_focus or _menu_stack.size() <= 1:
		return
	pop_self()


## Called when the menu has been pushed to the stack and it's on top, or when a menu on top of it has been popped and
## this menu ends up on top of the stack.
func _focus_in() -> void:
	if not _ready_called:
		Log.error(&"Menu", "Menu is overriding _ready and not calling the super method");

	show()
	update_focus()
	set_process_shortcut_input(true)


## Called when the menu has been removed from the stack or when a new menu is pushed on top of it.
func _focus_out() -> void:
	save_last_focus()
	if hide_on_focus_out and not _menu_stack.top is MenuPopup:
		hide()
	set_process_shortcut_input(false)


## Returns an element that should be focused automatically when using gamepad.
## By default returns the last focused element or uses the "default_focus" property, but can be overwritten.
func _get_default_focus() -> Control:
	if _last_focus:
		var last_focus := _last_focus
		_last_focus = null
		return last_focus

	for control in default_focus:
		if control and control.visible and (not control is BaseButton or (not control.disabled and control.focus_mode == Control.FocusMode.FOCUS_ALL)):
			return control

	return null


#endregion
