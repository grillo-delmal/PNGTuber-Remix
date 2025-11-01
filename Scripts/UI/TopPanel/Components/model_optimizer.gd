extends Window

var apply_trim : bool = false


func _ready() -> void:
	check_toggles()
	Global.project_updates.connect(check_toggles)

func _on_close_requested() -> void:
	hide()
	check_toggles()

func _on_image_trim_toggled(toggled_on: bool) -> void:
	if !Global.settings_dict.trimmed:
		apply_trim = toggled_on

func _on_apply_optimization_pressed() -> void:
	if !Global.settings_dict.trimmed:
		if Global.save_path != "":
			SaveAndLoad.save_file(Global.save_path.get_basename() + "Optimized" + ".pngRemix")
		else:
			SaveAndLoad.save_file(Settings.autosave_location + "/" + "Optimized" + str(randi())+ ".pngRemix")
		
		var save_path = Global.save_path
		SaveAndLoad.import_trimmed = true
		await get_tree().process_frame
		Global.new_file.emit()
		SaveAndLoad.load_file(save_path)
		await get_tree().process_frame
		SaveAndLoad.save_file(save_path)
		check_toggles()
		SaveAndLoad.import_trimmed = false

func _on_about_to_popup() -> void:
	check_toggles()


func check_toggles(_arg = ""):
	if !Global.settings_dict.trimmed:
		%ApplyOptimization.disabled = false
		%ImageTrim.disabled = false
	elif Global.settings_dict.trimmed:
		%ApplyOptimization.disabled = true
		%ImageTrim.disabled = true
