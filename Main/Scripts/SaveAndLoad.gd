extends Node


var save_dict : Dictionary = {}
var thread : Thread = Thread.new()
var trim : bool = false
var should_offset : bool = true
var import_flippd : bool = false

func save_file(path):
	if Settings.theme_settings.use_threading:
		if !thread.is_alive():
			var _err = thread.start(save_model.bind(path))
	else:
		save_model(path)

func save_model(path):
	Global.save_path = path
	var sprites = get_tree().get_nodes_in_group("Sprites")
	var inputs = get_tree().get_nodes_in_group("StateButtons")
	var sprites_array : Array = []
	var input_array : Array = []
	
	var image_array : Array = []
	

	for i in Global.image_manager_data:
		if !Settings.theme_settings.save_unused_files:
			var used : bool = false
			for sp in sprites:
				if sp.used_image_id == i.id or sp.used_image_id_normal == i.id:
					used = true
			if !used:
				continue
		var dict : Dictionary = i.get_data()
		image_array.append(dict)
		
		
	for input in inputs:
		input_array.append({
			state_name = input.state_name,
			hot_key = input.saved_event,
		})
	for sprt in sprites:
		sprt.save_state(Global.current_state)
		if !sprt.get_value("folder"):
			if sprt.referenced_data.is_apng:
				var cleaned_array = []
				for st in sprt.states:
					if !st.is_empty():
						cleaned_array.append(st)
				var sprt_dict = {
					states = cleaned_array,
					sprite_name = sprt.sprite_name,
					sprite_id = sprt.sprite_id,
					parent_id = sprt.parent_id,
					sprite_type = sprt.sprite_type,
					is_asset = sprt.is_asset,
					saved_event = sprt.saved_event,
					was_active_before = sprt.was_active_before,
					should_disappear = sprt.should_disappear,
					saved_keys = sprt.saved_keys,
					show_only = sprt.show_only,
					is_collapsed = sprt.is_collapsed,
					is_premultiplied = true,
					layer_color = sprt.layer_color,
					image_id = sprt.used_image_id,
					normal_id = sprt.used_image_id_normal,
				}
			else:
				var cleaned_array = []
				
				for st in sprt.states:
					if !st.is_empty():
						cleaned_array.append(st)
				var sprt_dict = {
					states = cleaned_array,
					sprite_name = sprt.sprite_name,
					sprite_id = sprt.sprite_id,
					parent_id = sprt.parent_id,
					sprite_type = sprt.sprite_type,
					is_asset = sprt.is_asset,
					saved_event = sprt.saved_event,
					was_active_before = sprt.was_active_before,
					should_disappear = sprt.should_disappear,
					show_only = sprt.show_only,
					saved_keys = sprt.saved_keys,
					is_collapsed = sprt.is_collapsed,
					is_premultiplied = true,
					layer_color = sprt.layer_color,
					rotated = sprt.rotated,
					flipped_h = sprt.flipped_h,
					flipped_v = sprt.flipped_v,
					image_id = sprt.used_image_id,
					normal_id = sprt.used_image_id_normal,
				}
				sprites_array.append(sprt_dict)
				
				sprites_array.append(sprt_dict)
		else:
			var cleaned_array = []
			
			for st in sprt.states:
				if !st.is_empty():
					cleaned_array.append(st)
			var sprt_dict = {
				states = cleaned_array,
				sprite_name = sprt.sprite_name,
				sprite_id = sprt.sprite_id,
				parent_id = sprt.parent_id,
				sprite_type = sprt.sprite_type,
				is_asset = sprt.is_asset,
				saved_event = sprt.saved_event,
				was_active_before = sprt.was_active_before,
				should_disappear = sprt.should_disappear,
				show_only = sprt.show_only,
				saved_keys = sprt.saved_keys,
				is_collapsed = sprt.is_collapsed,
				is_premultiplied = true,
				layer_color = sprt.layer_color,
				rotated = sprt.rotated,
				flipped_h = sprt.flipped_h,
				flipped_v = sprt.flipped_v,
				image_id = sprt.used_image_id,
				normal_id = sprt.used_image_id_normal,
			}
			sprites_array.append(sprt_dict)
		
	save_dict = {
		version = Global.version,
		sprites_array = sprites_array,
		settings_dict = Global.settings_dict,
		input_array = input_array,
		image_manager_data = image_array,
	}
	Settings.save()
	var file = FileAccess.open(path,FileAccess.WRITE)
#	if FileAccess.file_exists(path):
	#	print(file.get_var())
	
	file.store_var(save_dict, true)
	file.close()
	if Settings.theme_settings.use_threading:
		thread.call_deferred("wait_to_finish")
	
	Global.project_updates.emit("Project Saved!")

func load_file(path: String, autoload : bool = false):
	if autoload:
		Settings.theme_settings.path = path
		Settings.save()
	Global.save_path = path
	if Settings.theme_settings.use_threading:
		if !thread.is_alive():
			if path.get_extension() == "save":
				var _err = thread.start(load_pngplus_file.bind(path))
			else:
				var _err = thread.start(load_model.bind(path))
	else:
		if path.get_extension() == "save":
			load_pngplus_file(path)
		else:
			load_model(path)

func load_model(path : String):
	Global.delete_states.emit()
	Global.main.clear_sprites()
	
	Global.main.get_node("Timer").start()
	Global.delete_states.emit()
	await Global.main.get_node("Timer").timeout
	
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = file.get_var(true)
	file.close()
	
	if !load_dict.has("sprites_array"):
		return
	
	var file_version := ""
	if "version" in load_dict:
		file_version = load_dict.version
	
	if file_version != Global.version:
		if not path.begins_with("res://"):
			save_backup(load_dict, path)
			await get_tree().process_frame
		
		load_dict = VersionConverter.convert_save(load_dict, file_version)
		await get_tree().process_frame
		
		if OS.has_feature("editor") or not path.begins_with("res://"):
			var new_file := FileAccess.open(path, FileAccess.WRITE)
			new_file.store_var(load_dict, true)
			new_file.close()
			await get_tree().process_frame
	
	Global.settings_dict.merge(load_dict.settings_dict, true)
	if Global.settings_dict.monitor != Monitor.ALL_SCREENS:
		if Global.settings_dict.monitor >= DisplayServer.get_screen_count():
			Global.settings_dict.monitor = Monitor.ALL_SCREENS
	
	Global.remake_states.emit(load_dict.settings_dict.states)
	
	var local_image_manage = load_dict.get("image_manager_data", [])
	Global.image_manager_data = []
	for i in local_image_manage:
		var image_data : ImageData = ImageData.new()
		image_data.set_data(i)
		Global.image_manager_data.append(image_data)
	var has_image_data = load_dict.get("image_manager_data", null)
	if not path.begins_with("res://"):
		Global.save_path = path
	
	for sprite in load_dict.sprites_array:
		var sprite_obj
		if sprite.has("sprite_type"):
			if sprite.sprite_type == "Sprite2D":
				sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
			elif sprite.sprite_type == "WiggleApp":
				sprite_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn").instantiate()
				
		else:
			sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
			
		
		
		var cleaned_array = []
		
		for st in sprite.states:
			if !st.is_empty():
				cleaned_array.append(st)
				
		for st in cleaned_array:
			var new_dict = sprite_obj.sprite_data.duplicate()
			new_dict.merge(st, true)
			st = new_dict
			
		sprite_obj.states = cleaned_array
		sprite_obj.layer_color = sprite.get("layer_color", Color.BLACK)
		sprite_obj.used_image_id = sprite.get("image_id", 0)
		sprite_obj.used_image_id_normal = sprite.get("normal_id", 0)
		
		if sprite.has("is_asset"):
			sprite_obj.is_asset = sprite.is_asset
			sprite_obj.saved_event = sprite.saved_event
			sprite_obj.should_disappear = sprite.should_disappear
			if sprite.has("show_only"):
				sprite_obj.show_only = sprite.show_only
			sprite_obj.get_node("%Drag").visible = sprite.was_active_before
			sprite_obj.was_active_before = sprite.was_active_before
			sprite_obj.saved_keys = sprite.saved_keys
			if !InputMap.has_action(str(sprite.sprite_id)):
				InputMap.add_action(str(sprite.sprite_id))
				if sprite_obj.saved_event != null:
					InputMap.action_add_event(str(sprite.sprite_id), sprite_obj.saved_event)
		
		sprite_obj.sprite_name = sprite.sprite_name
		var image_data : ImageData 
		var image_data_normal : ImageData


		if !sprite_obj.states[0].get("folder", true):
			var canv = CanvasTexture.new()
			sprite_obj.get_node("%Sprite2D").texture = canv
			
			var set_text_diff = false
			var set_text_norm = false
			if has_image_data == null:
				image_data = ImageData.new()
				image_data_normal = ImageData.new()
				if sprite.has("is_apng"):
					load_apng(sprite, image_data)
					load_apng(sprite, image_data_normal, true)
					
				else:
					if sprite.has("img_animated"):
						if sprite.img_animated:
							load_gif(sprite_obj, sprite, image_data)
							load_gif(sprite, image_data_normal, true)
						else:
							load_sprite(sprite, image_data)
							load_sprite(sprite, image_data_normal, true)
					else:
						load_sprite(sprite, image_data)
						load_sprite(sprite, image_data_normal, true)
				if image_data.has_data:
					canv.diffuse_texture = image_data.runtime_texture
					sprite_obj.referenced_data = image_data
					sprite_obj.used_image_id = image_data.id
					image_data.image_name = sprite_obj.sprite_name
					Global.image_manager_data.append(image_data)
					set_text_diff = true
				if image_data_normal.has_data:
					canv.normal_texture = image_data_normal.runtime_texture
					sprite_obj.referenced_data_normal = image_data_normal
					sprite_obj.used_image_id_normal = image_data_normal.id
					image_data_normal.image_name = sprite_obj.sprite_name + "(Normal)"
					Global.image_manager_data.append(image_data_normal)
					set_text_norm = true
			else:
				sprite_obj.rotated = sprite.get("rotated", 0)
				sprite_obj.flipped_h = sprite.get("flipped_h", false)
				sprite_obj.flipped_v = sprite.get("flipped_v", false)
				for im in Global.image_manager_data:
					if im.id == sprite_obj.used_image_id:
						sprite_obj.referenced_data = im
						var texture = check_flips(im.runtime_texture, sprite_obj)
						sprite_obj.get_node("%Sprite2D").texture.diffuse_texture = texture
						set_text_diff = true
					if im.id == sprite_obj.used_image_id_normal:
						sprite_obj.referenced_data_normal = im
						var texture = check_flips(im.runtime_texture, sprite_obj)
						sprite_obj.get_node("%Sprite2D").texture.normal_texture = texture
						set_text_norm = true
			
			if sprite_obj.used_image_id != 0 && !set_text_diff:
				sprite_obj.get_node("%Sprite2D").texture.diffuse_texture = Global.image_data.runtime_texture
				sprite_obj.referenced_data = Global.image_data
			
			if sprite_obj.used_image_id_normal != 0 && !set_text_norm:
				sprite_obj.get_node("%Sprite2D").texture.normal_texture = Global.image_data_normal.runtime_texture
				sprite_obj.referenced_data_normal = Global.image_data_normal
		else:
			sprite_obj.get_node("%Sprite2D").texture = null

		
		if sprite.has("image_data"):
			if image_data != null:
				image_data.image_data = sprite.image_data 
			if image_data_normal != null:
				image_data_normal.image_data = sprite.normal_data 
		
		sprite_obj.sprite_id = sprite.sprite_id
		if sprite.parent_id != null:
			sprite_obj.parent_id = sprite.parent_id
		
		if sprite.has("is_collapsed"):
			sprite_obj.is_collapsed = sprite.is_collapsed
		sprite_obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		Global.sprite_container.add_child(sprite_obj)
		sprite_obj.get_state(0)


	if !load_dict.input_array.is_empty():
		for input in len(load_dict.input_array):
			if load_dict.input_array[input] is Dictionary:
				get_tree().get_nodes_in_group("StateButtons")[input].saved_event = load_dict.input_array[input].hot_key
				get_tree().get_nodes_in_group("StateButtons")[input].state_name = load_dict.input_array[input].state_name
				get_tree().get_nodes_in_group("StateButtons")[input].text = load_dict.input_array[input].state_name
				get_tree().get_nodes_in_group("StateButtons")[input].update_stuff()
			else:
				get_tree().get_nodes_in_group("StateButtons")[input].saved_event = load_dict.input_array[input]
				get_tree().get_nodes_in_group("StateButtons")[input].update_stuff()
				

	var state_count = get_tree().get_nodes_in_group("StateButtons").size()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.states.size() != state_count:
			for l in abs(i.states.size() - state_count):
				i.states.append({})
	
	Global.remake_layers.emit()
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))
	Global.slider_values.emit(Global.settings_dict)
	if Global.main.has_node("%Control"):
		Global.reinfoanim.emit()
	if Global.settings_dict.anti_alias:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if Global.settings_dict.auto_save:
		Settings.save_timer.wait_time = Global.settings_dict.auto_save_timer * 60
		Settings.save_timer.start()
	else:
		Settings.save_timer.stop()

	Global.main.get_node("%Marker").current_screen = Global.settings_dict.monitor
	Global.project_updates.emit("Project Loaded!")
	Global.remake_image_manager.emit()
	
	Global.load_sprite_states(0)
	if Settings.theme_settings.use_threading:
		thread.call_deferred("wait_to_finish")

func save_backup(data: Dictionary, previous_path: String) -> void:
	var base_path := previous_path.get_basename()
	var extension := "." + previous_path.get_extension()
	base_path += "_backup"
	
	var counter: int = 1
	var path := base_path + extension
	while FileAccess.file_exists(path):
		counter += 1
		path = base_path + str(counter) + extension
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data, true)

func load_sprite(sprite, image_data = null, normal = false):
	var img_data
	var img = Image.new()
	var type
	if normal:
		if sprite.normal == null:
			return
		type = sprite.normal
	else:
		if sprite.img == null:
			return
		type = sprite.img
		
	if type is not PackedByteArray:
		img_data = Marshalls.base64_to_raw(type)
		img.load_png_from_buffer(img_data)
	else:
		img.load_png_from_buffer(type)
	if sprite.has("is_premultiplied") == false:
		img.fix_alpha_edges()
	var img_tex = ImageTexture.new()
	img_tex.set_image(img)
	image_data.runtime_texture = img_tex
	image_data.has_data = true

func load_apng(sprite , image_data = null, normal = false):
	var buffer = []
	var img = null
	if normal:
		if sprite.normal == null:
			return
		img = AImgIOAPNGImporter.load_from_buffer(sprite.normal)
		buffer = sprite.normal
	else:
		if sprite.img == null:
			return
		img = AImgIOAPNGImporter.load_from_buffer(sprite.img)
		buffer = sprite.img
	var tex = img[1] as Array[AImgIOFrame]
	if image_data:
		image_data.is_apng = true
		image_data.frames = tex
		
	for n in image_data.frames:
		if sprite.has("is_premultiplied") == false:
			n.content.fix_alpha_edges()
	
	var cframe: AImgIOFrame = image_data.frames[0]
	image_data.is_apng = true
	image_data.img_animated = false
	image_data.anim_texture = buffer
	var text = ImageTexture.create_from_image(cframe.content)
	image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in image_data.frames:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		image_data.animated_frames.append(new_frame)
	
	image_data.has_data = true

func load_gif(sprite, image_data = null, normal = true):
	var buffer = []
	var gif_tex
	if normal:
		if sprite.normal == null:
			return
		gif_tex = GifManager.sprite_frames_from_buffer(sprite.normal)
		buffer = sprite.normal
	else:
		
		if sprite.img == null:
			return
		gif_tex = GifManager.sprite_frames_from_buffer(sprite.img)
		buffer = sprite.img
		
	for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
	var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
	image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
		new_frame.duration = gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i)/24
		image_data.animated_frames.append(new_frame)
	image_data.anim_texture = buffer
	image_data.img_animated = true
	image_data.is_apng = false
	image_data.has_data = true

func load_pngplus_file(path):
	Global.delete_states.emit()
	Global.main.clear_sprites()
	
	Global.main.get_node("Timer").start()
	await Global.main.get_node("Timer").timeout
	
	
	
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = JSON.parse_string(file.get_as_text())
	
	file.close()
	file = null
	
	
	if load_dict.size() < 1:
		return
	if !load_dict["0"].has("identification"):
		print("Failed")
		return
		
	for i in load_dict:
		var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
		var img_data = Marshalls.base64_to_raw(load_dict[i]["imageData"])
		if (load_dict[i]["frames"] > 1): #If animated, we don't want to trim the sprite
			var img = Image.new()
			img.load_png_from_buffer(img_data)
			var img_tex = ImageTexture.new()
			img_tex.set_image(img)
			var img_can = CanvasTexture.new()
			img_can.diffuse_texture = img_tex
			sprite_obj.get_node("%Sprite2D").texture = img_can
		else:
			var img_can = Global.main.get_node("%FileImporter").import_png_from_buffer(img_data, sprite_obj)
			sprite_obj.get_node("%Sprite2D").texture = img_can
		
	#	'''
	
		sprite_obj.is_plus_first_import = true
		sprite_obj.sprite_id = load_dict[i]["identification"]
		var id = load_dict[i].get("parentId", 0)
		if id == null:
			id = 0
		
		sprite_obj.parent_id = id
		sprite_obj.sprite_name = load_dict[i]["path"].get_file().trim_suffix(".png")
		
		sprite_obj.sprite_data.xFrq = load_dict[i]["xFrq"]
		sprite_obj.sprite_data.xAmp = float(load_dict[i]["xAmp"])
		sprite_obj.sprite_data.yFrq = load_dict[i]["yFrq"]
		sprite_obj.sprite_data.yAmp = float(load_dict[i]["yAmp"])
		sprite_obj.sprite_data.dragSpeed = load_dict[i]["drag"]
		sprite_obj.sprite_data.rdragStr = load_dict[i]["rotDrag"]
		sprite_obj.sprite_data.stretchAmount = load_dict[i]["stretchAmount"]
		sprite_obj.sprite_data.ignore_bounce = load_dict[i]["ignoreBounce"]
		sprite_obj.sprite_data.hframes = load_dict[i]["frames"]

		# convert PLUS animSpeed into Remix animation_speed (animation fps)
		# This assumes PLUS was set to thhe default Engine.max_fps of 60.
		var animSpeed = load_dict[i]["animSpeed"]
		if (animSpeed != 0.0) :
			sprite_obj.sprite_data.animation_speed = 60 / int(360.0 / float(animSpeed))
		
		if load_dict[i]["clipped"]:
			sprite_obj.sprite_data.clip = 2
		else:
			sprite_obj.sprite_data.clip = 0
		
		sprite_obj.sprite_data.rLimitMin = load_dict[i]["rLimitMin"]
		sprite_obj.sprite_data.rLimitMax = load_dict[i]["rLimitMax"]
		sprite_obj.sprite_data.z_index = load_dict[i]["zindex"]
		sprite_obj.sprite_data.position = str_to_var(load_dict[i]["pos"])
		sprite_obj.sprite_data.offset += str_to_var(load_dict[i]["offset"])

		var test = load_dict[i]["showBlink"]
		var test2 = load_dict[i]["showTalk"]
		
		if test == 0:
			sprite_obj.sprite_data.should_blink = false
			sprite_obj.sprite_data.open_eyes = false
		elif test == 1:
			sprite_obj.sprite_data.should_blink = true
			sprite_obj.sprite_data.open_eyes = true
		elif test == 2:
			sprite_obj.sprite_data.should_blink = true
			sprite_obj.sprite_data.open_eyes = false
		
		if test2 == 0:
			sprite_obj.sprite_data.should_talk = false
			sprite_obj.sprite_data.open_mouth = false
		elif test2 == 1:
			sprite_obj.sprite_data.should_talk = true
			sprite_obj.sprite_data.open_mouth = false
		elif test2 == 2:
			sprite_obj.sprite_data.should_talk = true
			sprite_obj.sprite_data.open_mouth = true
			
		
		sprite_obj.states = [{}]
		sprite_obj.states[0].merge(sprite_obj.sprite_data, true)
		
		var costume = str_to_var(load_dict[i]["costumeLayers"])
	#	print(costume)
		
		sprite_obj.states.resize(10)
		for l in costume.size():
			var ndict = sprite_obj.sprite_data.duplicate()
			if costume[l] == 0:
				ndict.visible = false
			else:
				ndict.visible = true
			sprite_obj.states[int(l)] = ndict
		Global.sprite_container.add_child(sprite_obj)
		sprite_obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		
	Global.remake_for_plus.emit()

	
	Global.load_sprite_states(0)
	Global.remake_layers.emit()
	Global.slider_values.emit(Global.settings_dict)
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))
	for i in get_tree().get_nodes_in_group("Sprites"):
		i.zazaza(get_tree().get_nodes_in_group("Sprites"))
	
	Global.settings_dict.should_delta = false
	Global.load_sprite_states(0)
	Global.reinfoanim.emit()
	Global.main.get_node("%Marker").current_screen = Monitor.ALL_SCREENS
	Global.load_model.emit()
	if Settings.theme_settings.use_threading:
		thread.call_deferred("wait_to_finish")
	Global.project_updates.emit("Plus Project Loaded!")

func export_images(_images = get_tree().get_nodes_in_group("Sprites")):
	#OS.get_executable_path().get_base_dir() + "/ExportedAssets" + "/" + str(randi())
	var dire = OS.get_executable_path().get_base_dir() + "/ExportedAssets"
	if !DirAccess.dir_exists_absolute(dire):
		DirAccess.make_dir_absolute(dire)
		
	for image in Global.image_manager_data:
		if image.img_animated:
			var file = FileAccess.open(dire +"/" + image.image_name + str(randi()) + ".gif", FileAccess.WRITE)
			file.store_buffer(image.anim_texture)
			file.close()
			file = null
		elif image.is_apng:
			var file = FileAccess.open(dire +"/" + image.image_name + str(randi()) + ".apng", FileAccess.WRITE)
			var exp_image = AImgIOAPNGExporter.new().export_animation(image.frames, 10, self, "_progress_report", [])
			file.store_buffer(exp_image)
			file.close()
			file = null
		elif !image.img_animated && !image.is_apng:
			var img = Image.new()
			img = image.runtime_texture.get_image()
			img.save_png(dire +"/" + image.image_name + str(randi()) + ".png")
			img = null
			if !image.image_data.is_empty():
				var img_d = Image.new()
				img_d.load_png_from_buffer(image.image_data)
				img_d.save_png(dire +"/" + image.image_name + str(randi()) + ".png")
				img_d = null

#----------------------------------------------------------------------------
# Global Image Loading Section
func import_gif(path : String, image_data):
	var g_file = FileAccess.get_file_as_bytes(path)
	var gif_tex : SpriteFrames = GifManager.sprite_frames_from_buffer(g_file)
	var img_can = CanvasTexture.new()
	for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
	var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
	img_can.diffuse_texture = text
	image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
		new_frame.duration = (gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i))/24
		image_data.animated_frames.append(new_frame)
		
	image_data.anim_texture = g_file
	image_data.img_animated = true
	image_data.is_apng = false
	image_data.image_name = "(Gif)" + path.get_file().get_basename() 

func import_apng_sprite(path : String ,image_data):
	var ap_file = FileAccess.get_file_as_bytes(path)
	var img = AImgIOAPNGImporter.load_from_file(path)
	var tex = img[1] as Array[AImgIOFrame]
	image_data.frames = tex
	
	for n in image_data.frames:
		n.content.fix_alpha_edges()
	
	var cframe: AImgIOFrame = image_data.frames[0]
	var text = ImageTexture.create_from_image(cframe.content)
	image_data.anim_texture = ap_file
	image_data.runtime_texture = text
	image_data.is_apng = true
	image_data.img_animated = false
	image_data.image_name = "(Apng) " + path.get_file().get_basename()
	image_data.animated_frames.clear()
	for i in image_data.frames:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		image_data.animated_frames.frames.append(new_frame)

func import_png(img: Image, spawn, image_data, _trim, _should_offset):
	var og_image = img.duplicate(true)
	if trim:
		img = ImageTrimmer.trim_image(img)
		image_data.trimmed = true
		if should_offset:
			var original_width = og_image.get_width()
			var original_height = og_image.get_height()
			var trimmed_width = img.get_width()
			var trimmed_height = img.get_height()
			# Calculate offset to maintain visual position
			var trim_info = ImageTrimmer.calculate_trim_info(og_image)
			var center_shift_x = trim_info.min_x - ((original_width - trimmed_width) / 2.0)
			var center_shift_y = trim_info.min_y - ((original_height - trimmed_height) / 2.0)
			image_data.offset = Vector2(center_shift_x, center_shift_y)
			# Adjust position to keep image visually stable
			if spawn != null:
				spawn.sprite_data.offset += Vector2(center_shift_x, center_shift_y)
				spawn.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
	image_data.is_apng = false
	image_data.img_animated = false
	img.fix_alpha_edges()
	var texture = ImageTexture.create_from_image(img)
	image_data.runtime_texture = texture

func import_png_from_file(path: String, spawn, image_data):
	var img = Image.load_from_file(path)
	SaveAndLoad.import_png(img, spawn, image_data, SaveAndLoad.trim, SaveAndLoad.should_offset)
	var buffer = FileAccess.get_file_as_bytes(path)
	if SaveAndLoad.trim:
		if Settings.theme_settings.save_raw_sprite:
			image_data.image_data = buffer
		else:
			image_data.image_data = []
	else:
		image_data.image_data = []
	image_data.image_name = path.get_file().get_basename()

#----------------------------------------------------------------------------
# Global Image loading from buffer
func load_apng_from_buffer(buffer , image_data = null, _normal = false):
	var img = AImgIOAPNGImporter.load_from_buffer(buffer)
	var tex = img[1] as Array[AImgIOFrame]
	image_data.frames = tex
	for n in image_data.frames:
		n.content.fix_alpha_edges()
	
	var cframe: AImgIOFrame = image_data.frames[0]
	image_data.is_apng = true
	image_data.img_animated = false
	var text = ImageTexture.create_from_image(cframe.content)
	image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in image_data.frames:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		image_data.animated_frames.append(new_frame)

func load_gif_from_buffer(buffer, image_data = null):
	var gif_tex = GifManager.sprite_frames_from_buffer(buffer)
	for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
	var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
	image_data.runtime_texture = text
	image_data.animated_frames.clear()
	for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
		new_frame.duration = gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i)/24
		image_data.animated_frames.append(new_frame)

func _on_flip_h(texture) -> Texture2D:
	var diff_img : Image = texture.get_image().duplicate(true)
	diff_img.flip_x()
	var diff_texture = ImageTexture.create_from_image(diff_img)
	return diff_texture

func _on_flip_v(texture) -> Texture2D:
	var diff_img : Image = texture.get_image().duplicate(true)
	diff_img.flip_y()
	var diff_texture = ImageTexture.create_from_image(diff_img)
	return diff_texture

func _on_rotate_image(texture, obj = null) -> Texture2D:
	var diff_img : Image = texture.get_image().duplicate(true)
	for i in obj.rotated:
		diff_img.rotate_90(CLOCKWISE)
	var diff_texture = ImageTexture.create_from_image(diff_img)
	return diff_texture

func check_flips(og_texture, object) -> Texture2D:
	var texture = og_texture
	if object.flipped_h:
		texture = _on_flip_h(texture)
	if object.flipped_v:
		texture = _on_flip_v(texture)
	if object.rotated != 0:
		texture = _on_rotate_image(texture, object)
	return texture

func check_valid(obj, image_data) -> bool:
	if obj != null && is_instance_valid(obj):
		if (image_data.is_apng or image_data.img_animated) or obj.get_value("folder"):
			return false
		return true
	else:
		return false
