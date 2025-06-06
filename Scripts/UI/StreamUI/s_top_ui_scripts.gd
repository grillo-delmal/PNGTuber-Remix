extends Node

var settings_scene = preload("res://UI/EditorUI/TopUI/Components/Settings_popup.tscn")
var is_editor : bool = true

func _ready() -> void:
	Global.top_ui = get_parent()
	%FileButton.get_popup().connect("id_pressed",choosing_files)
	%ModeButton.get_popup().connect("id_pressed",choosing_mode)
	%BGButton.get_popup().connect("id_pressed",choosing_bg_color)
	%WindowButton.get_popup().connect("id_pressed",choosing_window)
	

func choosing_files(id):
	match id:
		0:
			Global.main.load_file()
		1:
			pass
		2:
			pass
		3:
			if Global.swtich_session_popup != null && is_instance_valid(Global.swtich_session_popup):
				Global.swtich_session_popup.popup()

func choosing_mode(id):
	match id:
		0:
			Global.main.get_node("BG").show()
			get_viewport().transparent_bg = false
			RenderingServer.set_default_clear_color(Color.SLATE_GRAY)
			get_parent().get_parent().get_node("%UISplit").show()
			is_editor = true
		1:
			Global.main.get_node("BG").hide()
			RenderingServer.set_default_clear_color(Global.settings_dict.bg_color)
			get_viewport().transparent_bg = Global.settings_dict.is_transparent
			get_parent().get_parent().get_node("%UISplit").hide()
			is_editor = false

func choosing_bg_color(id):
	Global.settings_dict.is_transparent = false
	ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", false)
	ProjectSettings.set_setting("display/window/size/transparent", false)
	match id:
		0:
			Global.settings_dict.bg_color = Color.RED
		1:
			Global.settings_dict.bg_color =  Color.BLUE
		2:
			Global.settings_dict.bg_color = Color.GREEN
		3:
			Global.settings_dict.bg_color = Color.MAGENTA
		4:
			Global.settings_dict.bg_color = Color.DIM_GRAY
			ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", true)
			ProjectSettings.set_setting("display/window/size/transparent", true)
			Global.settings_dict.is_transparent  = true
		5:
			Global.settings_dict.bg_color = Color.SLATE_GRAY
			
		6:
			pass
			#%Background.popup()
	if not is_editor:
		RenderingServer.set_default_clear_color(Global.settings_dict.bg_color)
		get_viewport().transparent_bg = Global.settings_dict.is_transparent

func choosing_window(id):
	match id:
		0:
			Themes.toggle_borders()
		1:
			Themes.window_size_changed()
		2:
			%WindowButton.get_popup().toggle_item_checked(2)
			Themes.set_always_on_top(%WindowButton.get_popup().is_item_checked(2))
		3:
			Themes.center_window()

func _notification(what):
	if not is_editor:
		if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			get_parent().get_parent().show()
		elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			get_parent().get_parent().hide()

func _on_settings_button_pressed() -> void:
	Global.top_ui.add_child(settings_scene.instantiate())
