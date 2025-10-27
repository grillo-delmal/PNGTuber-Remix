extends Node


var save_dict : Dictionary = {}
var can_load_plus : bool = false
var appendage_scene = preload("res://Misc/AppendageObject/Appendage_object.tscn")
var sprite_scene = preload("res://Misc/SpriteObject/sprite_object.tscn")
const YIELD_EVERY : int = 25

var import_trimmed : bool = false

func save_file(path):
	save_model(path)

func save_data():
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
				sprites_array.append(sprt_dict)
				continue
				
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
				continue
				
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
			continue
		
	save_dict = {
		version = Global.version,
		sprites_array = sprites_array,
		settings_dict = Global.settings_dict,
		input_array = input_array,
		image_manager_data = image_array,
	}

func save_model(path):
	Global.save_path = path
	save_data()
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_var(save_dict, true)
	file.close()
	Global.project_updates.emit("Project Saved!")
	save_dict.clear()

func load_file(path: String, autoload : bool = false):
	if !FileAccess.file_exists(path):
		return
	if autoload:
		Settings.theme_settings.path = path
		Settings.save()
	Global.save_path = path
	can_load_plus = false
	if path.get_extension() == "save":
		can_load_plus = true
		load_pngplus_file(path)
	else:
		load_model(path)

func load_model(path: String) -> void:
	_reset_project_state()
	await Global.main.get_node("Timer").timeout
	
	var load_dict = await _read_and_maybe_convert_file(path)
	if load_dict == null:
		return
	await get_tree().process_frame
	
	_apply_settings(load_dict, path)
	await get_tree().process_frame
	
	_build_image_manager(load_dict)
	await get_tree().process_frame
	
	_build_and_add_sprites(load_dict)
	await get_tree().process_frame
	
	_apply_inputs(load_dict)
	await get_tree().process_frame
	
	_fix_sprite_states_to_count()
	
	_finalize_after_load()

func _reset_project_state() -> void:
	Global.delete_states.emit()
	Global.main.clear_sprites()
	Global.main.get_node("Timer").start()
	Global.delete_states.emit()

func _read_and_maybe_convert_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: %s" % path)
		return {}
	var load_dict = file.get_var(true)
	file.close()
	
	if not load_dict.has("sprites_array"):
		return {}
	
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
	
	return load_dict

func _apply_settings(load_dict: Dictionary, path: String) -> void:
	Global.settings_dict.merge(load_dict.settings_dict, true)
	if Global.settings_dict.monitor != Monitor.ALL_SCREENS:
		if Global.settings_dict.monitor >= DisplayServer.get_screen_count():
			Global.settings_dict.monitor = Monitor.ALL_SCREENS
	
	Global.remake_states.emit(load_dict.settings_dict.states)
	
	if not path.begins_with("res://"):
		Global.save_path = path

func _build_image_manager(load_dict: Dictionary) -> void:
	var local_image_manage = load_dict.get("image_manager_data", [])
	Global.image_manager_data = []
	for i in local_image_manage:
		var image_data : ImageData = ImageData.new()
		image_data.set_data(i)
		Global.image_manager_data.append(image_data)

func _build_and_add_sprites(load_dict: Dictionary) -> void:
	var image_cache := {}
	for im in Global.image_manager_data:
		image_cache[im.id] = im
	
	var to_add : Array = []
	var has_image_data = load_dict.get("image_manager_data", null)
	
	for sprite in load_dict.sprites_array:
		var sprite_obj
		if sprite.has("sprite_type"):
			if sprite.sprite_type == "Sprite2D":
				sprite_obj = sprite_scene.instantiate()
			elif sprite.sprite_type == "WiggleApp":
				sprite_obj = appendage_scene.instantiate()
			else:
				sprite_obj = sprite_scene.instantiate()
		else:
			sprite_obj = sprite_scene.instantiate()
		
		var cleaned_array := []
		for st in sprite.states:
			if not st.is_empty():
				cleaned_array.append(st)
		
		for i in range(cleaned_array.size()):
			var new_dict = sprite_obj.sprite_data.duplicate()
			new_dict.merge(cleaned_array[i], true)
			cleaned_array[i] = new_dict
		
		sprite_obj.states = cleaned_array
		sprite_obj.layer_color = sprite.get("layer_color", Color.BLACK)
		sprite_obj.used_image_id = sprite.get("image_id", 0)
		sprite_obj.used_image_id_normal = sprite.get("normal_id", 0)
		
		# asset-related fields
		if sprite.has("is_asset"):
			sprite_obj.is_asset = sprite.is_asset
			sprite_obj.saved_event = sprite.saved_event
			sprite_obj.should_disappear = sprite.should_disappear
			if sprite.has("show_only"):
				sprite_obj.show_only = sprite.show_only
			sprite_obj.get_node("%Drag").visible = sprite.was_active_before
			sprite_obj.was_active_before = sprite.was_active_before
			sprite_obj.saved_keys = sprite.saved_keys
			if not InputMap.has_action(str(sprite.sprite_id)):
				InputMap.add_action(str(sprite.sprite_id))
				if sprite_obj.saved_event != null:
					InputMap.action_add_event(str(sprite.sprite_id), sprite_obj.saved_event)
		
		sprite_obj.sprite_name = sprite.sprite_name
		
		var image_data : ImageData = null
		var image_data_normal : ImageData = null
		
		if not sprite_obj.states[0].get("folder", true):
			var canv := CanvasTexture.new()
			var sprite_node = sprite_obj.get_node("%Sprite2D")
			sprite_node.texture = canv
			
			var set_text_diff := false
			var set_text_norm := false
			
			if has_image_data == null:
				image_data = ImageData.new()
				image_data_normal = ImageData.new()
				
				if sprite.has("is_apng"):
					ImageTextureLoaderManager.load_apng(sprite, image_data)
					ImageTextureLoaderManager.load_apng(sprite, image_data_normal, true)
				else:
					if sprite.has("img_animated"):
						if sprite.img_animated:
							ImageTextureLoaderManager.load_gif(sprite_obj, sprite, image_data)
							ImageTextureLoaderManager.load_gif(sprite, image_data_normal, true)
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
					image_cache[image_data.id] = image_data
					set_text_diff = true
				if image_data_normal.has_data:
					canv.normal_texture = image_data_normal.runtime_texture
					sprite_obj.referenced_data_normal = image_data_normal
					sprite_obj.used_image_id_normal = image_data_normal.id
					image_data_normal.image_name = sprite_obj.sprite_name + "(Normal)"
					Global.image_manager_data.append(image_data_normal)
					image_cache[image_data_normal.id] = image_data_normal
					set_text_norm = true
			else:
				sprite_obj.rotated = sprite.get("rotated", 0)
				sprite_obj.flipped_h = sprite.get("flipped_h", false)
				sprite_obj.flipped_v = sprite.get("flipped_v", false)
				
				if image_cache.has(sprite_obj.used_image_id):
					var im = image_cache[sprite_obj.used_image_id]
					sprite_obj.referenced_data = im
					var tex = ImageTextureLoaderManager.check_flips(im.runtime_texture, sprite_obj)
					sprite_node.texture.diffuse_texture = tex
					set_text_diff = true
				if image_cache.has(sprite_obj.used_image_id_normal):
					var imn = image_cache[sprite_obj.used_image_id_normal]
					sprite_obj.referenced_data_normal = imn
					var texn := ImageTextureLoaderManager.check_flips(imn.runtime_texture, sprite_obj)
					sprite_node.texture.normal_texture = texn
					set_text_norm = true
			
			if sprite_obj.used_image_id != 0 and not set_text_diff:
				sprite_node.texture.diffuse_texture = Global.image_data.runtime_texture
				sprite_obj.referenced_data = Global.image_data
			if sprite_obj.used_image_id_normal != 0 and not set_text_norm:
				sprite_node.texture.normal_texture = Global.image_data_normal.runtime_texture
				sprite_obj.referenced_data_normal = Global.image_data_normal
		else:
			sprite_obj.get_node("%Sprite2D").texture = null
		
		if sprite.has("image_data"):
			if image_data != null:
				image_data.image_data = sprite.image_data
			if image_data_normal != null:
				image_data_normal.image_data = sprite.normal_data
		
		# Remaining metadata
		sprite_obj.sprite_id = sprite.sprite_id
		if sprite.parent_id != null:
			sprite_obj.parent_id = sprite.parent_id
		if sprite.has("is_collapsed"):
			sprite_obj.is_collapsed = sprite.is_collapsed
		
		sprite_obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		
		# Prepare to add to scene tree (we add in a second loop for smoother updates)
		to_add.append(sprite_obj)
		
	# add remaining
	for s in to_add:
		Global.sprite_container.add_child(s)
		s.get_state(0)

func _apply_inputs(load_dict: Dictionary) -> void:
	if load_dict.input_array == null:
		return
	var buttons = get_tree().get_nodes_in_group("StateButtons")
	var n = min(buttons.size(), load_dict.input_array.size())
	for i in range(n):
		var data = load_dict.input_array[i]
		var btn = buttons[i]
		if typeof(data) == TYPE_DICTIONARY:
			btn.saved_event = data.get("hot_key")
			btn.state_name = data.get("state_name", "")
			btn.text = data.get("state_name", "")
			btn.update_stuff()
		else:
			btn.saved_event = data
			btn.update_stuff()

func _fix_sprite_states_to_count() -> void:
	var state_count = get_tree().get_nodes_in_group("StateButtons").size()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.states.size() != state_count:
			for l in range(abs(i.states.size() - state_count)):
				i.states.append({})

func _finalize_after_load() -> void:
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

func load_pngplus_file(path):
	if not can_load_plus:
		return
	Global.delete_states.emit()
	Global.main.clear_sprites()
	Global.main.get_node("Timer").start()
	await Global.main.get_node("Timer").timeout
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = JSON.parse_string(file.get_as_text())
	file.close()
	file = null
	if load_dict == null or load_dict.size() < 1:
		return
	if not load_dict["0"].has("identification"):
		print("Failed to load PNGTuber Plus file: Missing identification.")
		return
	Global.image_manager_data = []
	Global.save_path = path
	var entries : Array = []
	var idx : int = 0
	for k in load_dict.keys():
		var d = load_dict[k]
		var z : int = 0
		if d.has("zindex"):
			if typeof(d.zindex) == TYPE_INT:
				z = d.zindex
			elif typeof(d.zindex) == TYPE_FLOAT:
				z = int(d.zindex)
			elif typeof(d.zindex) == TYPE_STRING and d.zindex.is_valid_integer():
				z = int(d.zindex)

		var ident := 0
		if d.has("identification"):
			ident = int(d.identification)
		entries.append({
			"key": k,
			"data": d,
			"zindex": z,
			"ident": ident,
			"orig_index": idx
		})
		idx += 1

	entries.sort_custom(func(a, b):
		if a.ident < b.orig_index:
			return 1
		return 0
	)

	for i in entries:
		var data = i.data
		var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
		var img_data = Marshalls.base64_to_raw(data["imageData"])
		var image_data = ImageData.new()
		var img = Image.new()
		img.load_png_from_buffer(img_data)
		if import_trimmed:
			var og_image = img.duplicate(true)
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
			sprite_obj.sprite_data.offset += Vector2(center_shift_x, center_shift_y)
			sprite_obj.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
		img.fix_alpha_edges()
		var tex = ImageTexture.create_from_image(img)
		image_data.runtime_texture = tex
		Global.image_manager_data.append(image_data)

		var canv = CanvasTexture.new()
		canv.diffuse_texture = image_data.runtime_texture
		sprite_obj.get_node("%Sprite2D").texture = canv

		sprite_obj.referenced_data = image_data
		sprite_obj.used_image_id = image_data.id
		sprite_obj.is_plus_first_import = true
		sprite_obj.sprite_id = data["identification"]

		var id = data.get("parentId", 0)
		if id == null:
			id = 0
		sprite_obj.parent_id = id

		sprite_obj.sprite_name = data["path"].get_file().trim_suffix(".png")

		# Apply all physics/motion data
		sprite_obj.sprite_data.xFrq = data["xFrq"]
		sprite_obj.sprite_data.xAmp = float(data["xAmp"])
		sprite_obj.sprite_data.yFrq = data["yFrq"]
		sprite_obj.sprite_data.yAmp = float(data["yAmp"])
		sprite_obj.sprite_data.dragSpeed = data["drag"]
		sprite_obj.sprite_data.rdragStr = data["rotDrag"]
		sprite_obj.sprite_data.stretchAmount = data["stretchAmount"]
		sprite_obj.sprite_data.ignore_bounce = data["ignoreBounce"]
		sprite_obj.sprite_data.hframes = data["frames"]

		var animSpeed = data["animSpeed"]
		if animSpeed != 0.0:
			sprite_obj.sprite_data.animation_speed = 60 / int(360.0 / max(float(animSpeed), 1.0))

		sprite_obj.sprite_data.clip = 2 if data["clipped"] else 0

		sprite_obj.sprite_data.rLimitMin = data["rLimitMin"]
		sprite_obj.sprite_data.rLimitMax = data["rLimitMax"]
		sprite_obj.sprite_data.z_index = data["zindex"]
		sprite_obj.sprite_data.position = str_to_var(data["pos"])
		sprite_obj.sprite_data.offset += str_to_var(data["offset"])

		# --- Blink and Talk ---
		var blink_mode = data["showBlink"]
		if blink_mode == 0:
			sprite_obj.sprite_data.should_blink = false
			sprite_obj.sprite_data.open_eyes = false
		elif blink_mode == 1:
			sprite_obj.sprite_data.should_blink = true
			sprite_obj.sprite_data.open_eyes = true
		elif blink_mode == 2:
			sprite_obj.sprite_data.should_blink = true
			sprite_obj.sprite_data.open_eyes = false

		var talk_mode = data["showTalk"]
		if talk_mode == 0:
			sprite_obj.sprite_data.should_talk = false
			sprite_obj.sprite_data.open_mouth = false
		elif talk_mode == 1:
			sprite_obj.sprite_data.should_talk = true
			sprite_obj.sprite_data.open_mouth = false
		elif talk_mode == 2:
			sprite_obj.sprite_data.should_talk = true
			sprite_obj.sprite_data.open_mouth = true

		# --- States ---
		sprite_obj.states = [{}]
		sprite_obj.states[0].merge(sprite_obj.sprite_data, true)
		var costume = str_to_var(data["costumeLayers"])
		sprite_obj.states.resize(10)
		for l in range(costume.size()):
			var ndict = sprite_obj.sprite_data.duplicate()
			ndict.visible = costume[l] != 0
			sprite_obj.states[l] = ndict

		Global.sprite_container.add_child(sprite_obj)
		sprite_obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		sprite_obj.get_state(0)


	Global.remake_for_plus.emit()
	Global.load_sprite_states(0)
	Global.remake_layers.emit()
	Global.slider_values.emit(Global.settings_dict)
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))

	for spr in get_tree().get_nodes_in_group("Sprites"):
		spr.zazaza(get_tree().get_nodes_in_group("Sprites"))

	Global.settings_dict.should_delta = false
	Global.load_sprite_states(0)
	Global.reinfoanim.emit()
	Global.remake_image_manager.emit()
	Global.main.get_node("%Marker").current_screen = Monitor.ALL_SCREENS
	Global.load_model.emit()
	Global.project_updates.emit("Plus Project Loaded!")

#----------------------------------------------------------------------------
# Global Backups
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
# Global Image loading from PSD
func load_images_from_psd(path : String):
	var loaded_layers : Array = []
	loaded_layers = PSDParser.open_photoshop_file(path)
	
	ImageTextureLoaderManager.trim = false
	ImageTextureLoaderManager.should_offset = false
	for layer in loaded_layers:
		#print(layer)
		if layer["type"] == "layer":
			var image_data : ImageData = ImageData.new()
			ImageTextureLoaderManager.import_png(layer["image"], null, image_data, false, false)
			image_data.image_name = layer["name"]
			image_data.offset = layer["offset"]
			image_data.trimmed = true
			Global.image_manager_data.append(image_data)
			Global.add_new_image.emit(image_data)
			add_objects_from_psd_data(layer, image_data)
		else:
			add_objects_from_psd_data(layer, null)
	Global.remake_layers.emit()
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))

func add_objects_from_psd_data(layer, image_data = null):
	var spawn
	if layer["type"] == "layer" && image_data != null:
		spawn = add_object_to_scene(image_data, false, false, true)
	else:
		spawn = add_object_to_scene(null, false, true, false, layer["name"])
	fix_ids(spawn, layer)

#----------------------------------------------------------------------------
# Global Simple Object addition
func add_object_to_scene(image_data, add_as_appendage : bool = false, folder : bool = false, force_offset : bool = false, custom_name : String = ""):
	var spawn 
	if add_as_appendage:
		spawn = appendage_scene.instantiate()
	else:
		spawn = sprite_scene.instantiate()
	if (ImageTextureLoaderManager.should_offset or force_offset) && !folder:
		spawn.sprite_data.offset += image_data.offset
		spawn.get_node("%Sprite2D").position += image_data.offset
	if !folder:
		var img_tex : CanvasTexture = CanvasTexture.new()
		img_tex.diffuse_texture = image_data.runtime_texture
		spawn.get_node("%Sprite2D").texture = img_tex
		spawn.sprite_name = image_data.image_name
		spawn.referenced_data = image_data
		spawn.used_image_id = image_data.id
	else:
		var canv = CanvasTexture.new()
		spawn.get_node("%Sprite2D").texture = canv
		spawn.sprite_name = custom_name
		spawn.sprite_data.folder = true
		
	spawn.sprite_id = spawn.get_instance_id()
	Global.sprite_container.add_child(spawn)
	if !force_offset && !folder:
		Global.update_layers.emit(0, spawn, "Sprite")
		ImageTrimmer.set_thumbnail(spawn.treeitem)
	var states = get_tree().get_nodes_in_group("StateButtons").size()
	for i in states:
		spawn.states.append(spawn.sprite_data.duplicate(true))
	 
	return spawn

static func fix_ids(spawn, fixed_ids):
	spawn.sprite_id = fixed_ids["id"]
	spawn.parent_id = fixed_ids["parent_id"]
