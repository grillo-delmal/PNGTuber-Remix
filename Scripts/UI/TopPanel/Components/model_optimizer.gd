extends Window

var apply_trim : bool = false

func _on_close_requested() -> void:
	hide()

func _on_image_trim_toggled(toggled_on: bool) -> void:
	apply_trim = toggled_on

func _on_apply_optimization_pressed() -> void:
	SaveAndLoad.save_data()
	var data = SaveAndLoad.save_dict.duplicate(true)
	SaveAndLoad.save_dict.clear()

	for img_dict in data.image_manager_data:
		if !img_dict.trimmed and !img_dict.img_animated:
			var img = Image.new()
			img.load_png_from_buffer(img_dict.runtime_texture)
			var trim_info = ImageTrimmer.calculate_trim_info(img)
			if !trim_info.is_empty():
				var og_image = img.duplicate(true)
				img = ImageTrimmer.trim_image(img)
				img_dict.runtime_texture = img.save_png_to_buffer()
				var original_width = og_image.get_width()
				var original_height = og_image.get_height()
				var trimmed_width = img.get_width()
				var trimmed_height = img.get_height()
				var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
				var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
				var delta = Vector2(center_shift_x, center_shift_y)
				img_dict.offset += delta
				img_dict.trimmed = true
				for sprt in data.sprites_array:
					if sprt.image_id == img_dict.id:
						for state in sprt.states:
							if state.has("offset"):
								state.offset += delta
	await get_tree().process_frame
	if Global.save_path != "":
		var path = Global.save_path.get_basename() + "Optimized.pngRemix"
		var file = FileAccess.open(path,FileAccess.WRITE)
		file.store_var(data, true)
		file.close()
		Global.project_updates.emit("Project Saved!")
		await get_tree().process_frame
		SaveAndLoad.load_file(path)
		
	else:
		var path = Settings.autosave_location + "/Optimized" + str(randi()) + ".pngRemix"
		var file = FileAccess.open(path,FileAccess.WRITE)
		file.store_var(data, true)
		file.close()
		Global.project_updates.emit("Project Saved!")

		await get_tree().process_frame
		SaveAndLoad.load_file(path)
