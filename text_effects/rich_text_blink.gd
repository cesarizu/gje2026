@tool
class_name RichTextBlink
extends RichTextEffect

## A rich text effect that creates a blinking animation for text.
##
## This effect makes text blink by toggling its visibility at a specified frequency.
## The blinking is achieved by modulating the alpha channel of the character's color.
##
## Usage example:
## [codeblock]
## [blink]This text will blink at default speed[/blink]
## [blink freq=2.0]This text blinks faster[/blink]
## [blink freq=0.5]This text blinks slower[/blink]
## [/codeblock]
##
## Parameters:
## - freq: Controls the blinking frequency in cycles per second (default: 1.0)
##         Higher values make the text blink faster, lower values make it blink slower.

## The BBCode tag name used to activate this effect.
## Use [blink]text[/blink] in RichTextLabel to apply the blinking effect.
var bbcode := "blink"


## Processes the blinking effect for each character.
##
## This method is called by the RichTextLabel for each character with the blink effect applied.
## It calculates whether the character should be visible based on elapsed time and frequency,
## then sets the alpha value accordingly.
##
## @param char_fx: The CharFXTransform containing character data and effect parameters.
##                 - env.get("freq", 1.0): Optional frequency parameter controlling blink speed.
##                 - elapsed_time: Time elapsed since the effect started.
##                 - color: The character's color that will be modified.
##
## @return: Always returns true to indicate the effect should be applied.
func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# Get parameters, or use the provided default value if missing.
	var speed: float = char_fx.env.get("freq", 1.0)

	var visible := fmod(char_fx.elapsed_time / speed, 1.0) > 0.5
	char_fx.color.a = 0 if visible else 1

	return true
