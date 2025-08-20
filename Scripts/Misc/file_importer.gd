extends Node

var sprite = preload("res://Misc/SpriteObject/sprite_object.tscn")
var appendage = preload("res://Misc/AppendageObject/Appendage_object.tscn")
var trim : bool = false

func import_sprite(path : String):
	var spawn = sprite.instantiate()
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	var img_tex : CanvasTexture 
	if path.get_extension() == "gif":
		img_tex = import_gif(path, spawn)
	elif apng_test != ["No frames", null]:
		img_tex = import_apng_sprite(path, spawn)
	else:
		img_tex = import_png_from_file(path, spawn)
	spawn.get_node("%Sprite2D").texture = img_tex
	return spawn

func import_appendage(path : String):
	var spawn = appendage.instantiate()
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	var img_tex : CanvasTexture 
	
	if path.get_extension() == "gif":
		img_tex = import_gif(path, spawn)
	elif apng_test != ["No frames", null]:
		img_tex = import_apng_sprite(path , spawn)
	else:
		img_tex = import_png_from_file(path, spawn)
	
	spawn.get_node("%Sprite2D").texture = img_tex
	return spawn

func import_apng_sprite(path : String , spawn) -> CanvasTexture:
	var img = AImgIOAPNGImporter.load_from_file(path)
	var tex = img[1] as Array[AImgIOFrame]
	spawn.frames = tex
	
	for n in spawn.frames:
		n.content.fix_alpha_edges()
	
	var cframe: AImgIOFrame = spawn.frames[0]
	var text = ImageTexture.create_from_image(cframe.content)
	var img_can = CanvasTexture.new()
	img_can.diffuse_texture = text
	spawn.is_apng = true
	spawn.sprite_name = "(Apng) " + path.get_file().get_basename()
	spawn.get_node("%AnimatedSpriteTexture").frames.clear()
	for i in spawn.frames:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		spawn.get_node("%AnimatedSpriteTexture").frames.append(new_frame)

	
	return img_can

func import_gif(path : String, spawn) -> CanvasTexture:
	var g_file = FileAccess.get_file_as_bytes(path)
	var gif_tex : SpriteFrames = GifManager.sprite_frames_from_buffer(g_file)
	var img_can = CanvasTexture.new()
	for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
	var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
	img_can.diffuse_texture = text
	spawn.get_node("%Sprite2D").texture = img_can
	spawn.get_node("%AnimatedSpriteTexture").frames.clear()
	for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
		new_frame.duration = (gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i))/24
		spawn.get_node("%AnimatedSpriteTexture").frames.append(new_frame)
	spawn.anim_texture = g_file
	spawn.img_animated = true
	spawn.is_apng = false
	spawn.sprite_name = "(Gif)" + path.get_file().get_basename() 
	return img_can

func import_png_from_file(path: String, spawn) -> CanvasTexture:
	var img = Image.load_from_file(path)
	var img_can = import_png(img, spawn)
	var buffer = FileAccess.get_file_as_bytes(path)
	if trim:
		if Settings.theme_settings.save_raw_sprite:
			spawn.image_data = buffer
		else:
			spawn.image_data = []
	else:
		spawn.image_data = []
	spawn.sprite_name = path.get_file().get_basename()
	return img_can
	
func import_png(img: Image, spawn) -> CanvasTexture:
	var og_image = img.duplicate(true)
	if trim:
		img = ImageTrimmer.trim_image(img)
		var original_width = og_image.get_width()
		var original_height = og_image.get_height()
		var trimmed_width = img.get_width()
		var trimmed_height = img.get_height()
		# Calculate offset to maintain visual position
		var trim_info = ImageTrimmer.calculate_trim_info(og_image)
		var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
		var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
		# Adjust position to keep image visually stable
		spawn.sprite_data.offset += Vector2(center_shift_x, center_shift_y)
		spawn.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)

	img.fix_alpha_edges()
	var texture = ImageTexture.create_from_image(img)
	var img_can = CanvasTexture.new()
	img_can.diffuse_texture = texture
	return img_can

func add_normal(path):
	if path.get_extension() == "gif":
		var g_file = FileAccess.get_file_as_bytes(path)
		var gif_tex : SpriteFrames = GifManager.sprite_frames_from_buffer(g_file)
		
		for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
			gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
		Global.held_sprites[0].anim_texture_normal = g_file
		var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
		Global.held_sprites[0].get_node("%Sprite2D").texture.normal_texture = text
		Global.held_sprites[0].get_node("%AnimatedSpriteTexture").frames2.clear()
		for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
			var new_frame : AnimatedFrame = AnimatedFrame.new()
			new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
			new_frame.duration = gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i)/24
			Global.held_sprites[0].get_node("%AnimatedSpriteTexture").frames2.append(new_frame)
			
	else:
		var apng_test = AImgIOAPNGImporter.load_from_file(path)
		if apng_test != ["No frames", null]:
			var img = AImgIOAPNGImporter.load_from_file(path)
			var tex = img[1] as Array[AImgIOFrame]
			Global.held_sprites[0].frames2 = tex
			
			for n in Global.held_sprites[0].frames2:
				n.content.fix_alpha_edges()
			
			var cframe: AImgIOFrame = Global.held_sprites[0].frames2[0]
			var text = ImageTexture.create_from_image(cframe.content)
			Global.held_sprites[0].get_node("%Sprite2D").texture.normal_texture = text
			for i in Global.held_sprites[0].frames2:
				var new_frame : AnimatedFrame = AnimatedFrame.new()
				new_frame.texture = ImageTexture.create_from_image(i.content)
				new_frame.duration = i.duration
				Global.held_sprites[0].get_node("%AnimatedSpriteTexture").frames2.append(new_frame)


		else:
			var img = Image.load_from_file(path)
			if trim:
				if !Global.held_sprites[0].image_data.is_empty():
					var og_image = Image.new()
					og_image.load_png_from_buffer(Global.held_sprites[0].image_data)
					img = ImageTrimmer.trim_normal(og_image, img)
					
			if trim:
				if Settings.theme_settings.save_raw_sprite:
					var buffer = FileAccess.get_file_as_bytes(path)
					Global.held_sprites[0].image_data = buffer
				else:
					Global.held_sprites[0].image_data = []
			else:
				Global.held_sprites[0].image_data = []
			img.fix_alpha_edges()
			var texture = ImageTexture.create_from_image(img)
			Global.held_sprites[0].get_node("%Sprite2D").texture.normal_texture = texture
		Global.get_sprite_states(Global.current_state)

func replace_texture(path : String):
	if path.get_extension().to_lower() == "gif":
		var g_file = FileAccess.get_file_as_bytes(path)
		var gif_tex : SpriteFrames = GifManager.sprite_frames_from_buffer(g_file)
		var img_can = CanvasTexture.new()
		for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
			gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
			
		var text = gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0)
		img_can.diffuse_texture = text
		Global.held_sprites[0].get_node("%Sprite2D").texture = img_can
		Global.held_sprites[0].get_node("%AnimatedSpriteTexture").frames.clear()
		for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
			var new_frame : AnimatedFrame = AnimatedFrame.new()
			new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
			new_frame.duration = gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i)/24
			Global.held_sprites[0].get_node("%AnimatedSpriteTexture").frames.append(new_frame)

		Global.held_sprites[0].anim_texture = g_file
		Global.held_sprites[0].anim_texture_normal = null
		Global.held_sprites[0].img_animated = true
		Global.held_sprites[0].is_apng = false
		Global.held_sprites[0].save_state(Global.current_state)
		ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
	else:
		var apng_test = AImgIOAPNGImporter.load_from_file(path)
		if apng_test != ["No frames", null]:
			var img = AImgIOAPNGImporter.load_from_file(path)
			var tex = img[1] as Array[AImgIOFrame]
			Global.held_sprites[0].frames = tex
			
			for n in Global.held_sprites[0].frames:
				n.content.fix_alpha_edges()
			
			var cframe: AImgIOFrame = Global.held_sprites[0].frames[0]
			var text = ImageTexture.create_from_image(cframe.content)
			var img_can = CanvasTexture.new()
			img_can.diffuse_texture = text
			ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
			Global.held_sprites[0].is_apng = true
			Global.held_sprites[0].img_animated = false
			Global.held_sprites[0].get_node("%AnimatedSpriteTexture").frames.clear()
			for i in Global.held_sprites[0].frames:
				var new_frame : AnimatedFrame = AnimatedFrame.new()
				new_frame.texture = ImageTexture.create_from_image(i.content)
				new_frame.duration = i.duration
				Global.held_sprites[0].get_node("%AnimatedSpriteTexture").frames.append(new_frame)
			
		else:
			var img = Image.load_from_file(path)
			var og_image = img.duplicate(true)
			if trim:
				img = ImageTrimmer.trim_image(img)
				var original_width = og_image.get_width()
				var original_height = og_image.get_height()
				var trimmed_width = img.get_width()
				var trimmed_height = img.get_height()
				# Calculate offset to maintain visual position
				var trim_info = ImageTrimmer.calculate_trim_info(og_image)
				var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
				var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
				# Adjust position to keep image visually stable
				var glob_pos : Array = []
				for i in Global.held_sprites[0].get_node("%Sprite2D").get_children():
					if i is SpriteObject:
						glob_pos.append({obj = i,
						og_pos = i.global_position})
				Global.held_sprites[0].sprite_data.offset += Vector2(center_shift_x, center_shift_y)
				Global.held_sprites[0].get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
				for i in glob_pos:
					i.obj.global_position = i.og_pos
					i.obj.sprite_data.position = i.obj.position
					i.obj.save_state(Global.current_state)
					
				Global.update_offset_spins.emit()
			if trim:
				if Settings.theme_settings.save_raw_sprite:
					var buffer = FileAccess.get_file_as_bytes(path)
					Global.held_sprites[0].image_data = buffer
				else:
					Global.held_sprites[0].image_data = []
			else:
				Global.held_sprites[0].image_data = []
				
			img.fix_alpha_edges()
			var texture = ImageTexture.create_from_image(img)
			var img_can = CanvasTexture.new()
			Global.held_sprites[0].img_animated = false
			Global.held_sprites[0].is_apng = false
			img_can.diffuse_texture = texture
			Global.held_sprites[0].get_node("%Sprite2D").texture = img_can
			Global.held_sprites[0].save_state(Global.current_state)
			ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
			
		if Global.held_sprites[0].sprite_type == "WiggleApp":
			Global.held_sprites[0].correct_sprite_size()
			Global.held_sprites[0].update_wiggle_parts()
		Global.held_sprites[0].get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	Global.get_sprite_states(Global.current_state)
	Global.reinfo.emit()

func _on_confirm_trim_confirmed() -> void:
	if get_parent().current_state == get_parent().State.AddNormal:
		trim = true
		add_normal(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.ReplaceSprite:
		trim = true
		replace_texture(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.LoadFile:
		trim = true
		SaveAndLoad.load_file(get_parent().model_path)
	else:
		trim = true
		get_parent().import_objects()

func _on_confirm_trim_canceled() -> void:
	if get_parent().current_state == get_parent().State.AddNormal:
		trim = false
		add_normal(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.ReplaceSprite:
		trim = false
		replace_texture(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.LoadFile:
		trim = false
		SaveAndLoad.load_file(get_parent().model_path)
	else:
		trim = false
		get_parent().import_objects()

func import_png_from_buffer(buffer, spawn) -> CanvasTexture:
	var img = Image.new()
	img.load_png_from_buffer(buffer)
	var og_image = img.duplicate(true)
	if trim:
		img = ImageTrimmer.trim_image(img)
		var original_width = og_image.get_width()
		var original_height = og_image.get_height()
		var trimmed_width = img.get_width()
		var trimmed_height = img.get_height()
		# Calculate offset to maintain visual position
		var trim_info = ImageTrimmer.calculate_trim_info(og_image)
		var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
		var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
		# Adjust position to keep image visually stable
		spawn.sprite_data.offset += Vector2(center_shift_x, center_shift_y)
		spawn.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
	img.fix_alpha_edges()
	var texture = ImageTexture.create_from_image(img)
	var img_can = CanvasTexture.new()
	img_can.diffuse_texture = texture
	return img_can
