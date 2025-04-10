extends Window

@export var container : Node

var editor_mode = preload("res://Main/main.tscn")
var streamer_mode = preload("res://Main/main_stream.tscn")
var current_mode : int = 0 

func _ready() -> void:
	Global.theme_update.connect(update_theme)
	close_requested.connect(close)

func _on_editor_mode_pressed() -> void:
	if current_mode != 0:
		for i in container.get_children():
			i.queue_free()
		
		container.add_child(editor_mode.instantiate())
		current_mode = 0


func _on_steamer_mode_pressed() -> void:
	if current_mode != 1:
		for i in container.get_children():
			i.queue_free()
		container.add_child(streamer_mode.instantiate())
		current_mode = 1


func update_theme(new_theme : Theme = preload("res://Themes/PurpleTheme/GUITheme.tres")):
	theme = new_theme

func close():
	hide()
