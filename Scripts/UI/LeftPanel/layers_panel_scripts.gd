extends Node

var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn")
var append_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn")
var has_folder : bool = false

func _ready() -> void:
	Settings.theme_changed.connect(change_theme)
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()

func change_theme(index):
	match index:
		0:
			%LayerPopup.theme = preload("res://Themes/PurpleTheme/GUITheme.tres")
		1:
			%LayerPopup.theme = preload("res://Themes/BlueTheme/BlueTheme.tres")
		2:
			%LayerPopup.theme = preload("res://Themes/OrangeTheme/OrangeTheme.tres")
		3:
			%LayerPopup.theme = preload("res://Themes/WhiteTheme/WhiteTheme.tres")
		4:
			%LayerPopup.theme = preload("res://Themes/DarkTheme/DarkTheme.tres")
		5:
			%LayerPopup.theme = preload("res://Themes/GreenTheme/Green_theme.tres")
		6:
			%LayerPopup.theme = preload("res://Themes/FunkyTheme/Funkytheme.tres")

func nullfy():
	%ReplaceButton.disabled = true
	%DuplicateButton.disabled = true
	%DeleteButton.disabled = true
	%AddNormalButton.disabled = true
	%DelNormalButton.disabled = true
	%RotateImage.disabled = false
	%FlipH.disabled = false
	%FlipV.disabled = false
	%RotateImage.disabled = true
	%FlipH.disabled = true
	%FlipV.disabled = true
	%UnlinkButton.disabled = true

func enable():
	%DuplicateButton.disabled = false
	%DeleteButton.disabled = false
	%UnlinkButton.disabled = false
	%RotateImage.disabled = true
	%FlipH.disabled = true
	%FlipV.disabled = true
	
	has_folder = false
	for i in Global.held_sprites:
		if i.get_value("folder") or Global.held_sprites.size() > 1:
			%AddNormalButton.disabled = true
			%DelNormalButton.disabled = true
			%ReplaceButton.disabled = true
			has_folder = true
		elif !i.get_value("folder") && !has_folder:
			%AddNormalButton.disabled = false
			%DelNormalButton.disabled = false
			%ReplaceButton.disabled = false
		else:
			%AddNormalButton.disabled = false
			%DelNormalButton.disabled = false
			%ReplaceButton.disabled = false
		if (i.is_apng or i.img_animated) or has_folder:
			%RotateImage.disabled = true
			%FlipH.disabled = true
			%FlipV.disabled = true
		else:
			%RotateImage.disabled = false
			%FlipH.disabled = false
			%FlipV.disabled = false

func _on_delete_button_pressed():
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.treeitem.free()
			i.free()
	Global.deselect.emit()

func _on_duplicate_button_pressed():
	var sprites : Array = []
	var id_map := {}

	for sprite in Global.held_sprites:
		if sprite != null and is_instance_valid(sprite):
			var layers_to_dup : Array = %LayersTree.get_all_layeritems_with_parent(sprite.treeitem, true)
			var obj

			if sprite.sprite_type == "WiggleApp":
				obj = append_obj.instantiate()
			else:
				obj = sprite_obj.instantiate()

			obj.position = sprite.position
			obj.scale = sprite.scale
			obj.sprite_data.scale = sprite.scale
			Global.sprite_container.add_child(obj)

			if obj.sprite_type != "Folder":
				obj.get_node("%Sprite2D").texture = sprite.get_node("%Sprite2D").texture

			obj.sprite_name = "Duplicate" + sprite.sprite_name 
			if sprite.get_value("folder"):
				obj.sprite_data.folder = true
			if sprite.img_animated:
				obj.img_animated = true
				obj.anim_texture = sprite.anim_texture
				obj.anim_texture_normal = sprite.anim_texture_normal 
			obj.sprite_data = sprite.sprite_data.duplicate(true)
			obj.states = sprite.states.duplicate(true)
			obj.saved_keys = sprite.saved_keys.duplicate(true)
			obj.should_disappear = sprite.should_disappear
			obj.show_only = sprite.show_only
			obj.is_asset = sprite.is_asset
			obj.saved_event = sprite.saved_event
			obj.was_active_before = sprite.was_active_before
			obj.visible = obj.was_active_before
			obj.is_collapsed = sprite.is_collapsed
			obj.played_once = sprite.played_once
			obj.layer_color = sprite.layer_color

			obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT

			obj.sprite_id = randi()
			id_map[sprite.sprite_id] = obj.sprite_id

			obj.parent_id = sprite.parent_id

			sprites.append(obj)
			Global.update_layers.emit(0, obj, obj.sprite_type)
			obj.get_state(Global.current_state)
			obj.global_position = sprite.global_position
			if obj.sprite_type == "WiggleApp":
				obj.update_wiggle_parts()


			for i in layers_to_dup:
				var t : SpriteObject = i.child.get_metadata(0).sprite_object
				var obj_to_spawn : SpriteObject

				if t.sprite_type == "WiggleApp":
					obj_to_spawn = append_obj.instantiate()
				else:
					obj_to_spawn = sprite_obj.instantiate()

				obj_to_spawn.scale = t.scale
				obj_to_spawn.sprite_data.scale = t.scale
				Global.sprite_container.add_child(obj_to_spawn)

				if obj_to_spawn.sprite_type != "Folder":
					obj_to_spawn.get_node("%Sprite2D").texture = t.get_node("%Sprite2D").texture

				obj_to_spawn.sprite_name = "Duplicate" + t.sprite_name
				if t.get_value("folder"):
					obj_to_spawn.sprite_data.folder = true
				if t.img_animated:
					obj_to_spawn.img_animated = true
					obj_to_spawn.anim_texture = t.anim_texture
					obj_to_spawn.anim_texture_normal = t.anim_texture_normal 

				obj_to_spawn.sprite_data = t.sprite_data.duplicate(true)
				obj_to_spawn.states = t.states.duplicate(true)
				obj_to_spawn.saved_keys = t.saved_keys.duplicate(true)
				obj_to_spawn.should_disappear = t.should_disappear
				obj_to_spawn.show_only = t.show_only
				obj_to_spawn.is_asset = t.is_asset
				obj_to_spawn.saved_event = t.saved_event
				obj_to_spawn.was_active_before = t.was_active_before
				obj_to_spawn.visible = obj_to_spawn.was_active_before
				obj_to_spawn.is_collapsed = t.is_collapsed
				obj_to_spawn.played_once = t.played_once
				obj_to_spawn.layer_color = t.layer_color
				obj_to_spawn.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT

				obj_to_spawn.sprite_id = randi()
				id_map[t.sprite_id] = obj_to_spawn.sprite_id

				if t.parent_id in id_map:
					obj_to_spawn.parent_id = id_map[t.parent_id]
				else:
					obj_to_spawn.parent_id = obj.sprite_id
				
				if t.sprite_type == "WiggleApp":
					obj_to_spawn.update_wiggle_parts()
				
				sprites.append(obj_to_spawn)
				Global.update_layers.emit(0, obj_to_spawn, obj_to_spawn.sprite_type)
				obj_to_spawn.get_state(Global.current_state)
				obj_to_spawn.global_position = t.global_position

	if sprites.is_empty():
		return

	Global.reparent_layers.emit(sprites)
	Global.reparent_objects.emit(sprites)

func _on_replace_button_pressed():
	Global.main.replacing_sprite()

func _on_add_sprite_button_pressed():
	Global.main.load_sprites()

func _on_folder_button_pressed():
	var sprte_obj = sprite_obj.instantiate()
	Global.sprite_container.add_child(sprte_obj)
	var canv = CanvasTexture.new()
	canv.diffuse_texture = preload("res://Misc/SpriteObject/Folder.png")
	sprte_obj.get_node("%Sprite2D").texture =  canv
	sprte_obj.sprite_name = str("Folder")
	sprte_obj.sprite_data.folder = true
	var states = get_tree().get_nodes_in_group("StateButtons").size()
	for i in states:
		sprte_obj.states.append({})
	Global.update_layers.emit(0, sprte_obj, "Sprite2D")
	sprte_obj.sprite_id = sprte_obj.get_instance_id()

func _on_add_normal_button_pressed():
	Global.main.add_normal_sprite()

func _on_del_normal_button_pressed():
	for sprite in Global.held_sprites:
		if sprite != null && is_instance_valid(sprite):
			if !sprite.is_apng:
				if not sprite.get_value("folder"):
					sprite.get_node("%Sprite2D").texture.normal_texture = null
					Global.reinfo.emit()
			elif sprite.is_apng or sprite.img_animated:
				if not sprite.get_value("folder"):
					sprite.get_node("%AnimatedSpriteTexture").frames2.clear()
					sprite.get_node("%Sprite2D").texture.normal_texture = null
					Global.reinfo.emit()

func _on_add_appendage_pressed() -> void:
	Global.main.load_append_sprites()

func _on_flip_h_pressed() -> void:
	if check_valid():
		var obj = Global.held_sprites[0]
		var sprite = obj.get_node("%Sprite2D")
		
		var diff_img : Image = sprite.texture.diffuse_texture.get_image().duplicate(true)
		diff_img.flip_x()
		var diff_texture = ImageTexture.create_from_image(diff_img)
		sprite.texture.diffuse_texture = diff_texture
		
		if sprite.texture.normal_texture != null && is_instance_valid(sprite.texture.normal_texture):
			var normal_img : Image = sprite.texture.diffuse_texture.get_image()
			normal_img.flip_x()
			var normal_texture = ImageTexture.create_from_image(normal_img)
			sprite.texture.normal_texture = normal_texture
		ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
		Global.reinfo.emit()
		
	else:
		return

func _on_flip_v_pressed() -> void:
	if check_valid():
		var obj = Global.held_sprites[0]
		var sprite = obj.get_node("%Sprite2D")
		
		var diff_img : Image = sprite.texture.diffuse_texture.get_image().duplicate(true)
		diff_img.flip_y()
		var diff_texture = ImageTexture.create_from_image(diff_img)
		sprite.texture.diffuse_texture = diff_texture
		
		if sprite.texture.normal_texture != null && is_instance_valid(sprite.texture.normal_texture):
			var normal_img : Image = sprite.texture.diffuse_texture.get_image()
			normal_img.flip_y()
			var normal_texture = ImageTexture.create_from_image(normal_img)
			sprite.texture.normal_texture = normal_texture
		ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
		Global.reinfo.emit()
	else:
		return

func _on_rotate_image_pressed() -> void:
	if check_valid():
		var obj = Global.held_sprites[0]
		var sprite = obj.get_node("%Sprite2D")
		
		var diff_img : Image = sprite.texture.diffuse_texture.get_image().duplicate(true)
		diff_img.rotate_90(CLOCKWISE)
		var diff_texture = ImageTexture.create_from_image(diff_img)
		sprite.texture.diffuse_texture = diff_texture
		
		if sprite.texture.normal_texture != null && is_instance_valid(sprite.texture.normal_texture):
			var normal_img : Image = sprite.texture.diffuse_texture.get_image()
			normal_img.rotate_90(CLOCKWISE)
			var normal_texture = ImageTexture.create_from_image(normal_img)
			sprite.texture.normal_texture = normal_texture
		if obj.sprite_type == "WiggleApp":
			var size = obj.correct_sprite_size(true)
			StateButton.multi_edit(size[0], "width", obj, obj.states)
			StateButton.multi_edit(size[1], "segm_length", obj, obj.states)
		ImageTrimmer.set_thumbnail(Global.held_sprites[0].treeitem)
		Global.reinfo.emit()
		
	else:
		return

func check_valid() -> bool:
	if Global.held_sprites.size() > 0:
		if Global.held_sprites[0] != null && is_instance_valid(Global.held_sprites[0]):
			if (Global.held_sprites[0].is_apng or Global.held_sprites[0].img_animated) or Global.held_sprites[0].get_value("folder"):
				return false
			return true
		else:
			return false
	else:
		return false

func _on_unlink_button_pressed() -> void:
	var has_unlinked : bool = false
	for sprite in Global.held_sprites:
		if sprite != null and is_instance_valid(sprite):
			if sprite.get_parent() == Global.sprite_container or sprite.parent_id == 0:
				continue
			else:
				has_unlinked = true
				var og_pos = sprite.global_position
				sprite.get_parent().remove_child(sprite)
				sprite.parent_id = 0
				Global.sprite_container.add_child(sprite)
				await get_tree().physics_frame
				sprite.global_position = og_pos
				sprite.sprite_data.position = sprite.position
				sprite.save_state(Global.current_state)
	if has_unlinked:
		Global.remake_layers.emit()
	
