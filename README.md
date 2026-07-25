# Holoprime UI Framework

## Setup

1. Copy `examples/controller_icons_data.tres` to `res://input/controller_icons_data.tres`
2. Add the following actions to the project settings:
    * `clicked`: with just a mouse click, used to detect clicks on shortcut buttons
    * `menu_back`: with 


## Menu

* Override `_get_default_focus` to return the default control that should be focused
* Override `_setup_menu` to allow the menu to receive parameters
