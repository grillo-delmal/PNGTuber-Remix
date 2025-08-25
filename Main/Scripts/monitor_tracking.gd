# Special thanks for Guuvita for the help implementing this feature
extends Control
class_name Monitor

const ALL_SCREENS = 9999
var current_screen = ALL_SCREENS
var coords : Vector2 = Vector2(0,0)
var screen_count = 0

func _ready():
	screen_count = DisplayServer.get_screen_count()

func _process(_delta):
	var global_mouse_pos = get_local_mouse_position()
	if current_screen == ALL_SCREENS:
		# All Screens mode
		coords = global_mouse_pos
	else:
		# Specific screen mode
		if (mouse_in_current_screen()):
			var screen_pos = DisplayServer.screen_get_position(current_screen)
			var relative_pos = Vector2i(global_mouse_pos) - screen_pos
			coords = Vector2i(relative_pos)
		else:
			if Global.settings_dict.snap_out_of_bounds:
				coords = Vector2i(0,0)
			else:
				var screen_pos = DisplayServer.screen_get_position(current_screen)
				var relative_pos = Vector2i(global_mouse_pos) - screen_pos
				coords = Vector2i(relative_pos)

func mouse_in_current_screen():
	var screen_pos = DisplayServer.screen_get_position(current_screen)
	var screen_size = DisplayServer.screen_get_size(current_screen)
	var mouse_pos = DisplayServer.mouse_get_position()
	return (mouse_pos.x >= screen_pos.x and mouse_pos.x < (screen_size.x + screen_pos.x) and 
			mouse_pos.y >= screen_pos.y and mouse_pos.y < (screen_size.y + screen_pos.y))
