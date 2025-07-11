extends Node

signal sprite_info 

@export var layers_popup: PopupMenu 
@export var tree : Tree 
@export var layer_buttons : Node

func _ready() -> void:
	var root = tree.create_item()
	root.set_text(0, "Model")
	root.set_icon(0, preload("res://UI/Assets/FolderButton.png"))
	Global.new_file.connect(delete_layers)
	Global.remake_layers.connect(remake_layers)
	Global.update_layers.connect(update_layers)
	layers_popup.connect("id_pressed",choosing_layers_popup)
	Global.deselect.connect(deselect_all)
	Global.update_layer_visib.connect(update_visib_buttons)
	Global.reparent_layers.connect(correct_rearrange)

func deselect_all():
	empty_sprites_array()

func choosing_layers_popup(id):
	var main = Global.main
	match id:
		0:
			main.load_sprites()
		1:  
			layer_buttons._on_folder_button_pressed()
		2:#replace
			main.replacing_sprite()
		3:#duplicate
			layer_buttons._on_duplicate_button_pressed()
		4:#Delete
			layer_buttons._on_delete_button_pressed()
		5:#add normal
			main.add_normal_sprite()
		6: #delete normal
			layer_buttons._on_del_normal_button_pressed()
		7: #Deselect
			Global.deselect.emit()
			tree.deselect_all()
		8:
			if Global.held_sprites.size() > 0:
				for i in Global.held_sprites:
					if i != null && is_instance_valid(i):
						pass
					else:
						return
					
					
					%PopupColor.position = get_viewport().get_mouse_position() + Vector2(0,%PopupColor.size.y/2)
					%PopupColor.popup()

func update_layers(update_type : int, new_item = null, type : String = "Sprite"):
	match update_type:
		0:
			if new_item != null:
				add_new_layer_item(new_item, type)

func add_new_layer_item(new_item, type, recolor = false, layer_color = Color.TRANSPARENT):
	var new_layer_item : TreeItem = tree.create_item(tree.get_root())
	new_layer_item.set_metadata(0,{
		sprite_object = new_item,
		parent = new_layer_item,
	})
	new_layer_item.set_icon_max_width(0,25)
	if type == "Sprite2D":
		if new_item.sprite_data.folder:
			new_layer_item.set_icon(0,preload("res://UI/Assets/FolderButton.png"))
		else:
			ImageTrimmer.set_thumbnail(new_layer_item)
	elif type == "WiggleApp":
		ImageTrimmer.set_thumbnail(new_layer_item)
	new_layer_item.set_text(0, new_item.sprite_name)
	new_layer_item.add_button(0, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton.png"))
	if recolor && layer_color != Color.BLACK:
		new_layer_item.set_custom_bg_color(0, Color(layer_color.r, layer_color.g, layer_color.b, 0.45))
	
	new_item.treeitem = new_layer_item

func delete_layers():
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "Model")
	root.set_icon(0, preload("res://UI/Assets/FolderButton.png"))
	root.set_icon_max_width(0,25)

func remake_layers(sprites : Array = get_tree().get_nodes_in_group("Sprites")):
	delete_layers()
	for i in sprites:
		add_new_layer_item(i, i.sprite_type, true, i.layer_color)
		
	correct_rearrange(sprites)
	update_visib_buttons()
	collapsing(sprites)

func correct_rearrange(sprites : Array = get_tree().get_nodes_in_group("Sprites")):
	for i in sprites:
		for l in sprites:
			if i.parent_id == l.sprite_id:
				var parent = i.treeitem.get_parent()
				parent.remove_child(i.treeitem)
				l.treeitem.add_child(i.treeitem)
	correct_recolor()

func update_visib_buttons():
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.sprite_data.visible:
			i.treeitem.set_button(0,0, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton.png"))
		elif not i.sprite_data.visible:
			i.treeitem.set_button(0,0, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton2.png"))

func collapsing(sprites):
	for i in sprites:
		if i.treeitem.get_children().size() > 0:
			i.treeitem.collapsed = i.is_collapsed

func _on_layers_tree_item_collapsed(item: TreeItem) -> void:
	item.get_metadata(0).sprite_object.is_collapsed = item.collapsed

func _on_layers_tree_empty_clicked(_click_position: Vector2, _mouse_button_index: int) -> void:
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if Global.held_sprite.has_node("%Origin"):
			Global.held_sprite.get_node("%Origin").hide()
	Global.held_sprite = null
	tree.deselect_all()
	Global.deselect.emit()

func _on_layers_tree_button_clicked(item: TreeItem, column: int, id: int, _mouse_button_index: int) -> void:
	if id == 0 && column == 0:
		item.get_metadata(0).sprite_object.sprite_data.visible =! item.get_metadata(0).sprite_object.sprite_data.visible 
		item.get_metadata(0).sprite_object.visible = item.get_metadata(0).sprite_object.sprite_data.visible 
		item.get_metadata(0).sprite_object.save_state(Global.current_state)
		if item.get_metadata(0).sprite_object.visible:
			item.set_button(column, id, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton.png"))
		elif not item.get_metadata(0).sprite_object.visible:
			item.set_button(column, id, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton2.png"))

func _on_layers_tree_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("rmb"):
		layers_popup.popup(Rect2i(get_parent().get_global_mouse_position().x,get_parent().get_global_mouse_position().y, 100,100 ))

func _on_layers_tree_multi_selected(item: TreeItem, _column: int, selected: bool) -> void:
	call_deferred("select_items", item, _column, selected)

func select_items(_item: TreeItem, _column: int, _selected: bool):
	var cleaned_array : Array[SpriteObject] = []
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.treeitem.is_selected(0):
			cleaned_array.append(i)
		
	Global.held_sprites = cleaned_array
	
	if Global.held_sprites.size() > 0:
		Global.reinfo.emit()
	else:
		Global.deselect.emit()

func empty_sprites_array():
	tree.deselect_all()
	Global.held_sprites.clear()

func _on_layer_color_color_changed(color: Color) -> void:
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			i.layer_color = color
			if color == Color.BLACK:
				i.treeitem.set_custom_bg_color(0,Color.TRANSPARENT)
			else:
				i.treeitem.set_custom_bg_color(0,Color(color.r, color.g, color.b, 0.45))
			correct_recolor()

func correct_recolor():
	var layers = %LayersTree.get_all_layeritems(%LayersTree.get_root(), true)
	for item in layers:
		var meta = item.get_metadata(0)
		if meta == null or not meta.has("sprite_object"):
			continue

		var sprite = meta.sprite_object
		if sprite == null:
			continue

		var color = sprite.layer_color
		var is_inherited = false

		if color == Color.BLACK:
			var parent = item.get_parent()
			while parent:
				var parent_meta = parent.get_metadata(0)
				if parent_meta != null and parent_meta.has("sprite_object"):
					var parent_sprite = parent_meta.sprite_object
					if parent_sprite != null:
						var parent_color = parent_sprite.layer_color
						if parent_color != Color.BLACK:
							color = parent_color
							is_inherited = true
							break
				parent = parent.get_parent()

		if color != Color.BLACK:
			var alpha = 0.45
			if is_inherited:
				alpha = 0.35
			item.set_custom_bg_color(0, Color(color.r, color.g, color.b, alpha))
		else:
			item.set_custom_bg_color(0, Color.TRANSPARENT)
