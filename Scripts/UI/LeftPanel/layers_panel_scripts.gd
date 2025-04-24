extends Node

var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn")
var append_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn")

func _ready() -> void:
	Themes.theme_changed.connect(change_theme)
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)

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
	if Global.held_sprite.sprite_data.folder:
		%AddNormalButton.disabled = true
		%DelNormalButton.disabled = true
		%ReplaceButton.disabled = true
	else:
		%AddNormalButton.disabled = false
		%DelNormalButton.disabled = false
		%ReplaceButton.disabled = false

func _on_delete_button_pressed():
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.treeitem.free()
		Global.held_sprite.queue_free()
		Global.held_sprite = null
		Global.deselect.emit()

func _on_duplicate_button_pressed():
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		var layers_to_dup : Array = %LayersTree.get_all_layeritems_with_parent(Global.held_sprite.treeitem, true)
		var sprites : Array = []
		var obj
		if Global.held_sprite.sprite_type == "WiggleApp":
			obj = append_obj.instantiate()
			
		else:
			obj = sprite_obj.instantiate()
		obj.scale = Global.held_sprite.scale
		obj.sprite_data.scale = Global.held_sprite.scale
		Global.sprite_container.add_child(obj)
		if obj.sprite_type != "Folder":
			obj.get_node("%Sprite2D").texture = Global.held_sprite.get_node("%Sprite2D").texture
		obj.sprite_name = "Duplicate" + Global.held_sprite.sprite_name 

		if Global.held_sprite.sprite_data.folder:
			obj.sprite_data.folder = true
		
		if Global.held_sprite.img_animated:
			obj.img_animated = true
			obj.anim_texture = Global.held_sprite.anim_texture
			obj.anim_texture_normal = Global.held_sprite.anim_texture_normal 
		
		obj.sprite_data = Global.held_sprite.sprite_data.duplicate()
		obj.states = Global.held_sprite.states.duplicate()
		obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	#	Global.update_layers.emit(0, obj, obj.sprite_type)
		obj.sprite_id = Global.held_sprite.treeitem.get_instance_id()
		obj.parent_id = Global.held_sprite.parent_id
		sprites.append(obj)
		if Global.held_sprite.get_parent() is Sprite2D or Global.held_sprite.get_parent() is WigglyAppendage2D:
			sprites.append(Global.held_sprite.get_parent().owner)
		
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

			if i.child.get_metadata(0).sprite_object.sprite_data.folder:
				obj_to_spawn.sprite_data.folder = true
			
			if i.child.get_metadata(0).sprite_object.img_animated:
				obj_to_spawn.img_animated = true
				obj_to_spawn.anim_texture = i.child.get_metadata(0).sprite_object.anim_texture
				obj_to_spawn.anim_texture_normal = i.child.get_metadata(0).sprite_object.anim_texture_normal 
			
			obj_to_spawn.sprite_data = i.child.get_metadata(0).sprite_object.sprite_data.duplicate()
			obj_to_spawn.states = i.child.get_metadata(0).sprite_object.states.duplicate()
			obj_to_spawn.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
			Global.update_layers.emit(0, obj_to_spawn, obj_to_spawn.sprite_type)
			obj_to_spawn.sprite_id = i.child.get_instance_id()
			obj_to_spawn.parent_id = i.parent.get_instance_id()
			sprites.append(obj_to_spawn)
		
		Global.remake_layers.emit()
		Global.reparent_objects.emit(sprites)
		
		obj.get_state(Global.current_state)


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
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if !Global.held_sprite.is_apng:
			if not Global.held_sprite.sprite_data.folder:
				Global.held_sprite.get_node("%Sprite2D").texture.normal_texture = null

func _on_add_appendage_pressed() -> void:
	Global.main.load_append_sprites()
