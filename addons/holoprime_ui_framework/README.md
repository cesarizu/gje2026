# Holoprime UI Framework

A Godot 4 UI framework providing a menu navigation system, adaptive shortcut icons for controller/keyboard/mouse/touch, a data binding system (MVVM-style), and debug UI utilities.

> 🚧 Disclaimer: This addon is under heavy development and may change significantly between updates.

# Installation

Copy the contents of `addons/holoprime_ui_framework` into your project, or use git:

```bash
git remote add holoprime_ui_framework https://gitlab.com/holopri.me/addons/holoprime_ui_framework.git
git fetch holoprime_ui_framework
git subtree add --prefix addons/holoprime_ui_framework --squash --message="Added Holopri.me UI Framework addon" holoprime_ui_framework/split
```

If you are using git LFS, add this to `.gitattributes`:

```
addons/holoprime_ui_framework/** -filter -diff -merge -text
```

To update:

```bash
git fetch holoprime_ui_framework
git subtree merge --prefix addons/holoprime_ui_framework --squash --message="Updated Holopri.me UI Framework addon" holoprime_ui_framework/split
```

## What It Includes

- Autoloads: `MultiplayerInput`, `InputManager`, `ControllerIcons`
- Menus: `Menu`, `MenuStack`, `MenuPopup`
- Shortcut helpers: `ShortcutButton`, `ShortcutContainer`, `ShortcutTexture2D`, `ShortcutRichTextLabel`
- Data binding: `BindingContext`, `ValueBinding`, `VisibilityBinding`, `ListBinding`, `InstantiateBinding`, `DataSourceBinding`, `BindingCommand`, `ViewModel`
- Text effect: `RichTextBlink`

## Setup

1. Enable the plugin in `Project > Project Settings > Plugins`.
2. Add required actions in `Project > Project Settings > Input Map`:
   - `clicked` (used by shortcut buttons/containers when simulating shortcuts)
   - `menu_back` (used for menu back/cancel handling)
3. Optional debug actions (only if you use `DebugUI`):
   - `debug_open_menu_1`
   - `debug_open_menu_2`

When enabled, the plugin registers:

- `MultiplayerInput` -> `res://addons/holoprime_ui_framework/input/multiplayer_input.gd`
- `InputManager` -> `res://addons/holoprime_ui_framework/input/input_manager.gd`
- `ControllerIcons` -> `res://addons/holoprime_ui_framework/input/controller_icons.gd`

## Menu Quickstart

```gdscript
# game/ui/ui.gd
extends Node

@onready var menu_stack: MenuStack = %MenuStack

func _ready() -> void:
    MenuStack.main_stack = menu_stack
    menu_stack.reset_to(start_menu_scene)
```

```gdscript
extends Menu

func _ready() -> void:
    super()

func _get_default_focus() -> Control:
    return %PlayButton

func _setup_menu(player_id: int) -> void:
    pass
```

Notes:

- If you override `Menu._ready()`, call `super()`.
- `_setup_menu` is called only when its parameter count matches `MenuStack.push(...)`.
- `menu_back` is handled in `Menu._shortcut_input()` and calls `_on_back_pressed()`.

## Controller Icons

`ControllerIcons.get_icon(event)` resolves icons using:

- current input method from `InputManager`
- controller matching/fallback prefixes from `controller_detection_config.tres`
- optional override data

Built-in icon data path:

- `res://addons/holoprime_ui_framework/input/controller_icons_data.tres`

Controller matching config path:

- `res://addons/holoprime_ui_framework/input/controller_detection_config.tres`

Override example:

```gdscript
@export var custom_icons: ControllerIconsData

func _ready() -> void:
    ControllerIcons.controller_icons_data_override = custom_icons
```

Icon dictionary format:

- `prefix -> action_key -> Texture2D`
- keyboard examples: `enter`, `escape`, `space`, `q`
- mouse examples: `button_1`, `button_2`
- gamepad examples: `button_0`, `axis_0`

## Shortcuts

- `ShortcutButton`: updates its icon by input method and simulates its shortcut on click.
- `ShortcutTexture2D`: dynamic texture that resolves the active icon for a `Shortcut`.
- `ShortcutRichTextLabel`: replaces `[input]action_name[/input]` tags with live icons.

Example:

```text
Press [input]menu_back[/input] to return.
```

## Data Binding

Core pattern:

1. Add `BindingContext` under the root bindable node.
2. Set the data source at runtime.
3. Add binding nodes under controls (`ValueBinding`, `ListBinding`, etc.).

```gdscript
extends Menu

var vm := MyViewModel.new()

func _ready() -> void:
    super()
    BindingContext.set_data_source(self, vm)
```

Bindings evaluate expressions with Godot `Expression` against the bound data source.
Template strings in `ValueBinding` use `{...}` placeholders.

## Rich Text Blink

`RichTextBlink` is a `RichTextEffect` for `[blink]...[/blink]`.
Add it to `RichTextLabel.custom_effects`, then use:

```text
[blink]Warning[/blink]
[blink freq=2.0]Fast blink[/blink]
```

## Common Pitfalls

- Shortcut actions do not fire: make sure `clicked` exists.
- Back/cancel does nothing: make sure `menu_back` exists.
- Menu focus feels broken: overridden `Menu._ready()` must call `super()`.
- `_setup_menu` not called: argument count must match `MenuStack.push(...)`.
- Wrong gamepad icons: verify `controller_detection_config.tres` match/fallback rules.
- No icon shown: missing `prefix + action_key` entry in `ControllerIconsData.icons`.
