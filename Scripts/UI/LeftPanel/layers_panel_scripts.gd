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

func enable():
	%DuplicateButton.disabled = false
	%DeleteButton.disabled = false
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

func _on_delete_button_pressed():
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.treeitem.free()
			i.queue_free()
	Global.deselect.emit()

func _on_duplicate_button_pressed():
	var sprites : Array = []
	for sprite in Global.held_sprites:
		if sprite != null && is_instance_valid(sprite):
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
		#	Global.update_layers.emit(0, obj, obj.sprite_type)
			obj.sprite_id = sprite.treeitem.get_instance_id()
			obj.parent_id = sprite.parent_id
			sprites.append(obj)
			Global.update_layers.emit(0, obj, obj.sprite_type)
			obj.get_state(Global.current_state)
			obj.global_position = sprite.global_position
				
			if sprite.get_parent() is Sprite2D or sprite.get_parent() is WigglyAppendage2D:
				sprites.append(sprite.get_parent().owner)
			
			
			for i in layers_to_dup:
				var obj_to_spawn : SpriteObject
				if i.child.get_metadata(0).sprite_object.sprite_type == "WiggleApp":
					obj_to_spawn = append_obj.instantiate()
				else:
					obj_to_spawn = sprite_obj.instantiate()
					
				obj_to_spawn.scale = i.child.get_metadata(0).sprite_object.scale
				obj_to_spawn.sprite_data.scale = i.child.get_metadata(0).sprite_object.scale
				Global.sprite_container.add_child(obj_to_spawn)
				if obj_to_spawn.sprite_type != "Folder":
					obj_to_spawn.get_node("%Sprite2D").texture = i.child.get_metadata(0).sprite_object.get_node("%Sprite2D").texture
				obj_to_spawn.sprite_name = "Duplicate" + i.child.get_metadata(0).sprite_object.sprite_name 

				if i.child.get_metadata(0).sprite_object.get_value("folder"):
					obj_to_spawn.sprite_data.folder = true
				
				if i.child.get_metadata(0).sprite_object.img_animated:
					obj_to_spawn.img_animated = true
					obj_to_spawn.anim_texture = i.child.get_metadata(0).sprite_object.anim_texture
					obj_to_spawn.anim_texture_normal = i.child.get_metadata(0).sprite_object.anim_texture_normal 
				
				obj_to_spawn.sprite_data = i.sprite_data.duplicate(true)
				obj_to_spawn.states = i.states.duplicate(true)
				obj_to_spawn.saved_keys = i.saved_keys.duplicate(true)
				obj_to_spawn.should_disappear = i.should_disappear
				obj_to_spawn.show_only = i.show_only
				obj_to_spawn.is_asset = i.is_asset
				obj_to_spawn.saved_event = i.saved_event
				obj_to_spawn.was_active_before = i.was_active_before
				obj_to_spawn.visible = obj_to_spawn.was_active_before
				obj_to_spawn.is_collapsed = i.is_collapsed
				obj_to_spawn.played_once = i.played_once
				obj_to_spawn.layer_color = i.layer_color
				obj_to_spawn.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
				obj_to_spawn.sprite_id = i.child.get_instance_id()
				obj_to_spawn.parent_id = i.parent.get_instance_id()
				sprites.append(obj_to_spawn)
				Global.update_layers.emit(0, obj_to_spawn, obj_to_spawn.sprite_type)
				obj_to_spawn.get_state(Global.current_state)
				obj_to_spawn.global_position = i.child.get_metadata(0).sprite_object.global_position
		
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
