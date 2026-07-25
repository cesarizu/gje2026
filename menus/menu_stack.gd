class_name MenuStack
extends CanvasLayer
## A menu stack that holds a list of menus and helps navigate through them.
##
## Has methods to push, pop and query the stack.

## Emitted when a menu has been pushed on the stack
signal menu_pushed(menu: Menu)

## Emitted when a menu has been popped from the stack
signal menu_popped(menu: Menu)

static var main_stack: MenuStack

## The menu on top of the stack
var top: Menu:
	get:
		return null if _stack.is_empty() else _stack.front() if is_instance_valid(_stack.front()) else null

## The menu at the bottom of the stack
var bottom: Menu:
	get:
		return null if _stack.is_empty() else _stack.back()

var _stack: Array[Menu] = []

#region Public methods

## Finds the "owner" Menu of a node (i.e. Finds the first Menu ancestor of a node that is inside a MenuStack.)
static func find_menu(node: Node) -> Menu:
	while node:
		if node is MenuStack:
			return node.top
		node = node.get_parent()
	return null


## The number of menus in this stack
func size() -> int:
	return _stack.size()


## Indicates whether a menu is empty or not
func is_empty() -> int:
	return _stack.is_empty()


## Pushes a menu on top of the stack, passing some parameters.
## @param menu This can be a PackedScene or a Menu.
func push(menu: Variant, ...params) -> Menu:
	if menu is PackedScene:
		menu = menu.instantiate()

	if menu is not Menu:
		Log.warn(&"MenuStack", "Trying to push an object not recognized as a menu: %s" % menu)
		return null

	_push.bindv(params).call(menu)

	return top


## Ensures that there's just one menu in the stack, either by popping all menus on top (if the menu was the bottom menu)
## or cleaning the stack and pushin a new menu.
## @param menu This can be a PackedScene or a Menu.
func reset_to(menu: Variant, ...params) -> Menu:
	if menu is PackedScene:
		menu = menu.instantiate()

	if menu is not Menu:
		Log.warn(&"MenuStack", "Trying to push an object not recognized as a menu: %s" % menu)
		return null

	if bottom and bottom.name == menu.name:
		pop_to(bottom)
	else:
		pop_all()
		_push.bindv(params).call(menu)

	return top


## Pops the menu on top
func pop_top() -> void:
	_pop(top)


## Clear all menus above the requested menu
func pop_to(menu: Menu) -> bool:
	while top:
		if top == menu:
			return true
		pop_top()
	return false


## Pops all menus in the stack
func pop_all() -> void:
	pop_to(null)


## Checkes if the menu is on top
func is_on_top(menu: Menu) -> bool:
	return top == menu


## This adds the menu to the stack when the menu is pre-instantiated on a scene.
func try_set_as_top(menu: Menu) -> void:
	if is_empty():
		_push(menu)


## Get a menu by type
func get_menu(menu_type: Variant) -> Menu:
	for menu in _stack:
		if is_instance_of(menu, menu_type):
			return menu

	return null


## Pop a specific menu, might not be in order
func pop(menu: Menu) -> void:
	_pop(menu)

#endregion

#region Private methods

## Push the menu to the top of the stack
func _push(menu: Menu, ...params) -> void:
	var prev_top := top

	# Menu parent is the inmediate previous menu in it's stack.
	menu.parent = prev_top

	if menu.has_method(&"_setup_menu"):
		var arg_count := menu.get_method_argument_count(&"_setup_menu")
		if arg_count == params.size():
			menu.callv("_setup_menu", params)
		else:
			Log.warn(&"MenuStack", "Not initializing menu %s because it needs %d parameters and can only receive %d" % [menu, params.size(), arg_count])
	elif params.size() > 0:
		Log.warn(&"MenuStack", "Not initializing menu %s because it needs %d parameters and doesn't implement _setup_menu" % [menu, params.size()])

	_stack.push_front(menu)
	Log.debug(&"MenuStack", "_push(%s, %s) stack=%s" % [menu, params, _stack])

	# Blur the previous top menu, if any
	if prev_top:
		await _blur_menu(prev_top, false)

	if not menu.get_parent():
		add_child(menu)

	menu_pushed.emit(menu)

	await _focus_menu(top)


## Pops this menu, blurring it if it was the top menu and focusing the next top menu if it has changed.
func _pop(menu: Menu) -> void:
	var was_top := menu == top

	if was_top:
		await _blur_menu(menu, true)
		_stack.pop_front()
	else:
		var index := _stack.find(menu)
		if index != -1:
			_stack.remove_at(index)

	Log.debug(&"MenuStack", "_pop(%s) top=%s stack=%s" % [menu, top, _stack])

	if menu.get_parent():
		menu.get_parent().remove_child(menu)
	menu.queue_free()

	menu_popped.emit(menu)

	# Focus the next menu, if any
	if was_top and not _stack.is_empty():
		await _focus_menu(top)


## Called when a menu needs focus
func _focus_menu(menu: Menu) -> void:
	menu.has_focus = true
	await menu._focus_in()


## Called when a menu is blurred
func _blur_menu(menu: Menu, from_pop: bool) -> void:
	menu.has_focus = false
	menu.is_popped = from_pop
	await menu._focus_out()


#endregion


#region Deprecated


## @deprecated: Use [method push]
func push_menu(menu: Menu, ...params) -> Menu:
	return push.bindv(params).call(menu)


## @deprecated: Use [method reset_to]
func push_on_top(menu_packed_scene: PackedScene, params := []) -> Menu:
	return reset_to(menu_packed_scene)


## @deprecated: Use [method reset_to]
func push_menu_on_top(menu: Menu, params := []) -> Menu:
	return reset_to(menu)


#endregion
