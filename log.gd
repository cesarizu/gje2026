## Class that allows logging with some control.
##
## Has different channels and levels. Can be enabled or disabled. Can be used as a singleton.
@tool
class_name Log

## Debug levels
enum Level { DEBUG, INFO, WARNING, ERROR }

## Config for a logging channel
class ChannelConfig:
	var enabled: Dictionary[Level, bool] = {} ## The enabled state of the channel for each level

## Defines if a level is enabled by default
static var DEFAULT_ENABLED: Dictionary[Level, bool] = {
	Level.DEBUG: false,
	Level.INFO: OS.is_debug_build() or Engine.is_editor_hint(),
	Level.WARNING: OS.is_debug_build() or Engine.is_editor_hint(),
	Level.ERROR: true,
}

## The logging config by channel
static var channels: Dictionary[StringName, ChannelConfig] = {}

static var _last_color := 0.0


## Log a debug message. [param message] can be a Callable that will only execute if the logging is enabled.
static func debug(channel: StringName, message: Variant) -> void:
	if is_enabled(channel, Level.DEBUG):
		print_rich("[color=%s][%s][/color] %s" % [_get_color(channel), channel, message.call() if message is Callable else message])


## Log a info message.
static func info(channel: StringName, message: String) -> void:
	if is_enabled(channel, Level.INFO):
		print_rich("[color=%s][%s][/color] [color=darkgreen]%s" % [_get_color(channel), channel, message])


## Log a warning message.
static func warn(channel: StringName, message: String) -> void:
	if is_enabled(channel, Level.WARNING):
		print_rich("[color=%s][%s][/color] [color=orange]%s" % [_get_color(channel), channel, message])


## Log an error message.
static func error(channel: StringName, message: String) -> void:
	if is_enabled(channel, Level.ERROR):
		print_rich("[color=%s][%s][/color] [color=red]%s" % [_get_color(channel), channel, message])


## Enable or disable a channel for a specific level.
static func set_enabled(channel: StringName, level: Level, enabled: bool) -> void:
	var channel_config: ChannelConfig = channels.get_or_add(channel, ChannelConfig.new())

	channel_config.enabled.set(level, enabled)


## Check if a channel is enabled for a specific level.
static func is_enabled(channel: StringName, level: Level) -> bool:
	if channel not in channels or level not in channels[channel].enabled:
		return DEFAULT_ENABLED[level]

	return channels[channel].enabled[level]


static func _get_color(channel: StringName) -> String:
	var hue := 1.0 * channel.hash() / ((1 << 32) - 1)
	return Color.from_hsv(hue, 0.5, 1.0).to_html(false)
