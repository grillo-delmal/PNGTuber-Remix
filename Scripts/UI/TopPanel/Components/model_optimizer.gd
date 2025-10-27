extends Window

var apply_trim : bool = false

func _on_close_requested() -> void:
	hide()

func _on_image_trim_toggled(toggled_on: bool) -> void:
	apply_trim = toggled_on

func _on_apply_optimization_pressed() -> void:
	# to enable the button in top ui, look for the Top_ui scene and look for the FilesButton and go to the last page in the items
	pass
	
	'''
	for img in Global.image_manager_data:
		if !img.is_apng && !img.img_animated:
			var og_image = img.runtime_texture.get_image().duplicate(true)
			var trim_info = ImageTrimmer.calculate_trim_info(og_image)
			
			var image = img.runtime_texture.get_image().duplicate(true)
			image = ImageTrimmer.trim_image(image)
			var original_width = og_image.get_width()
			var original_height = og_image.get_height()
			var trimmed_width = image.get_width()
			var trimmed_height = image.get_height()
			if trim_info.is_empty():
				continue
			var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
			var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
			img.runtime_texture.set_image(image)
			img.offset += Vector2(center_shift_x, center_shift_y)
			img.trimmed = true

	for obj in get_tree().get_nodes_in_group("Sprites"):
		if !obj.sprite_data.folder:
			var trim_offset = obj.referenced_data.offset
			var total_offset = trim_offset - obj.sprite_data.offset 
			obj.sprite_data.offset += total_offset
			for state in obj.states:
				if state.has("offset"):
					var total_offset_state = trim_offset - state.offset
					state.offset += total_offset_state

	await get_tree().process_frame
	if Global.save_path != "":
		SaveAndLoad.save_file(Global.save_path.get_basename() + "Optimized" + ".pngRemix")
	else:
		SaveAndLoad.save_file(Settings.autosave_location + "/" + "Optimized" + str(randi())+ ".pngRemix")

	await get_tree().process_frame
	SaveAndLoad.load_file(Global.save_path)'''
