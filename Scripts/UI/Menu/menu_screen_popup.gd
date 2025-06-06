extends AcceptDialog

@export var container : Node

var editor_mode = preload("res://Main/main.tscn")
var streamer_mode = preload("res://Main/main_stream.tscn")
var current_mode : int = 0 

func _ready() -> void:
	Global.theme_update.connect(update_theme)
	close_requested.connect(close)
	confirmed.connect(close)
	await get_tree().current_scene.ready
	switch_sessions()
	

func _on_editor_mode_pressed() -> void:
	if current_mode != 0:
		Global.delete_states.emit()
		for i in container.get_children():
			i.queue_free()
		
		container.add_child(editor_mode.instantiate())
		Themes.theme_settings.session = 0
		current_mode = 0


func _on_steamer_mode_pressed() -> void:
	if current_mode != 1:
		Global.delete_states.emit()
		for i in container.get_children():
			i.queue_free()
		container.add_child(streamer_mode.instantiate())
		Themes.theme_settings.session = 1
		current_mode = 1


func switch_sessions():
	if Themes.theme_settings.session != current_mode:
		if Themes.theme_settings.session == 0:
			Global.delete_states.emit()
			for i in container.get_children():
				i.queue_free()
			
			container.add_child(editor_mode.instantiate())
			current_mode = 0
			
		elif Themes.theme_settings.session == 1:
			Global.delete_states.emit()
			for i in container.get_children():
				i.queue_free()
			container.add_child(streamer_mode.instantiate())
			current_mode = 1
		



func update_theme(new_theme : Theme = preload("res://Themes/PurpleTheme/GUITheme.tres")):
	theme = new_theme

func close():
	hide()
