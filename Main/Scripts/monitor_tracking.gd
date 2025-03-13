# Special thanks for Guuvita for the help implementing this feature
extends Control

const ALL_SCREENS_ID = 9999
var current_screen = ALL_SCREENS_ID
var screen_count = 0
var coords : Vector2 = Vector2(0,0)

func _ready():
	screen_count = DisplayServer.get_screen_count()

func _process(_delta):
	var global_mouse_pos = get_local_mouse_position()
	if current_screen == ALL_SCREENS_ID:
		# All Screens mode
		coords = global_mouse_pos
	else:
		# Specific screen mode
		var screen_pos = DisplayServer.screen_get_position(current_screen)
		var screen_size = DisplayServer.screen_get_size(current_screen)
		var relative_pos = Vector2i(global_mouse_pos) - screen_pos
		
		if (DisplayServer.mouse_get_position().x >= screen_pos.x and DisplayServer.mouse_get_position().x < (screen_size.x + screen_pos.x) and 
			DisplayServer.mouse_get_position().y >= screen_pos.y and DisplayServer.mouse_get_position().y < (screen_size.y + screen_pos.y)):
			coords = Vector2i(relative_pos)
		else:
			coords = Vector2i(0,0)
