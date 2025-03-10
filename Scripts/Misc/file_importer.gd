extends Node

var sprite = preload("res://Misc/SpriteObject/sprite_object.tscn")
var appendage = preload("res://Misc/AppendageObject/Appendage_object.tscn")
var trim : bool = false

func import_sprite(path : String):
	var spawn = sprite.instantiate()
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	var img_tex : CanvasTexture 
	if apng_test != ["No frames", null]:
		img_tex = import_apng_sprite(path, spawn)
	else:
		img_tex = import_png(path, spawn)
	spawn.get_node("%Sprite2D").texture = img_tex
	return spawn

func import_appendage(path : String):
	var spawn = appendage.instantiate()
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	var img_tex : CanvasTexture 
	if apng_test != ["No frames", null]:
		img_tex = import_apng_sprite(path , spawn)
	else:
		img_tex = import_png(path, spawn)
	
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
	return img_can

func import_png(path : String, spawn) -> CanvasTexture:
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
		spawn.dictmain.offset += Vector2(center_shift_x, center_shift_y)
		spawn.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
	var buffer = FileAccess.get_file_as_bytes(path)
	spawn.image_data = buffer

	img.fix_alpha_edges()
	var texture = ImageTexture.create_from_image(img)
	var img_can = CanvasTexture.new()
	img_can.diffuse_texture = texture
	spawn.sprite_name = path.get_file().get_basename()
	return img_can

func add_normal(path):
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	if apng_test != ["No frames", null]:
		var img = AImgIOAPNGImporter.load_from_file(path)
		var tex = img[1] as Array[AImgIOFrame]
		Global.held_sprite.frames2 = tex
		
		for n in Global.held_sprite.frames2:
			n.content.fix_alpha_edges()
		
		var cframe: AImgIOFrame = Global.held_sprite.frames2[0]
		var text = ImageTexture.create_from_image(cframe.content)
		Global.held_sprite.get_node("%Sprite2D").texture.normal_texture = text

	else:
		var img = Image.load_from_file(path)
		if trim:
			if !Global.held_sprite.image_data.is_empty():
				var og_image = Image.new()
				og_image.load_png_from_buffer(Global.held_sprite.image_data)
				img = ImageTrimmer.trim_normal(og_image, img)
		Global.held_sprite.normal_data = FileAccess.get_file_as_bytes(path)
		img.fix_alpha_edges()
		var texture = ImageTexture.create_from_image(img)
		Global.held_sprite.get_node("%Sprite2D").texture.normal_texture = texture
	Global.get_sprite_states(Global.current_state)

func replace_texture(path):
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	if apng_test != ["No frames", null]:
		var img = AImgIOAPNGImporter.load_from_file(path)
		var tex = img[1] as Array[AImgIOFrame]
		Global.held_sprite.frames = tex
		
		for n in Global.held_sprite.frames:
			n.content.fix_alpha_edges()
		
		var cframe: AImgIOFrame = Global.held_sprite.frames[0]
		var text = ImageTexture.create_from_image(cframe.content)
		var img_can = CanvasTexture.new()
		img_can.diffuse_texture = text
		Global.held_sprite.treeitem.get_node("%Icon").texture = Global.held_sprite.texture
		Global.held_sprite.is_apng = true
		Global.held_sprite.img_animated = false
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
			Global.held_sprite.dictmain.offset += Vector2(center_shift_x, center_shift_y)
			Global.held_sprite.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
			Global.update_offset_spins.emit()
		var buffer = FileAccess.get_file_as_bytes(path)
		Global.held_sprite.image_data = buffer
			
		var texture = ImageTexture.create_from_image(img)
		var img_can = CanvasTexture.new()
		img.fix_alpha_edges()
		Global.held_sprite.img_animated = false
		Global.held_sprite.is_apng = false
		img_can.diffuse_texture = texture
		Global.held_sprite.get_node("%Sprite2D").texture = img_can
		Global.held_sprite.save_state(Global.current_state)
		Global.held_sprite.treeitem.get_node("%Icon").texture = texture
		
	if Global.held_sprite.sprite_type == "WiggleApp":
		Global.held_sprite.correct_sprite_size()
		Global.held_sprite.update_wiggle_parts()
	Global.held_sprite.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	Global.get_sprite_states(Global.current_state)
	Global.reinfo.emit()

func _on_confirm_trim_confirmed() -> void:
	if get_parent().current_state == get_parent().State.AddNormal:
		trim = true
		add_normal(get_parent().sprite_path)
	elif get_parent().current_state == get_parent().State.ReplaceSprite:
		trim = true
		replace_texture(get_parent().sprite_path)
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
	else:
		trim = false
		get_parent().import_objects()
