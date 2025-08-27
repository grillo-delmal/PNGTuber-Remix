extends MarginContainer

var held_button : Control = null
var checked_sprited : Array = []
var held_items_assets : Array[TreeItem] = []
var paths_placeholder = []

func _ready() -> void:
	Global.remake_image_manager.connect(remake_files)
	Global.add_new_image.connect(add_file)
	
	create_default()

func create_default():
	%Tree.clear()
	var root : TreeItem = %Tree.create_item()
	root.set_text(0, "File System")
	root.set_selectable(0, false)
	
	var assets : TreeItem = %Tree.create_item(root)
	assets.set_text(0, "Assets")
	assets.set_selectable(0, false)
	
	var extensions : TreeItem = %Tree.create_item(root)
	extensions.set_text(0, "Extensions")
	extensions.set_selectable(0, false)

func _on_collapse_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%CollapseButton.icon = preload("res://UI/Assets/Collapse1.png")
		
	else:
		%CollapseButton.icon = preload("res://UI/Assets/Collapse2.png")
		
	%ManageContain.visible = toggled_on

func open_popup(node : Control):
	held_button = node
	print(node)

func remake_files():
	held_button = null
	create_default()
	for i in Global.image_manager_data:
		add_file(i)

func add_file(file : ImageData):
		var spawn : TreeItem = %Tree.create_item(%Tree.get_root().get_child(0))
		spawn.set_metadata(0, file)
		spawn.set_text(0, file.image_name)
		ImageTrimmer.set_thumbnail(spawn)

func _on_add_image_button_pressed() -> void:
	%FileDialog.filters = ["*.png, *.apng, *.gif", "*.png", "*.jpeg", "*.jpg", "*.svg", "*.apng"]
	%OffsetSprite.button_pressed = SaveAndLoad.should_offset
	%FileDialog.popup()

func _on_replace_button_pressed() -> void:
	pass # Replace with function body.

func _on_delete_button_pressed() -> void:
	check_sprites()
	if checked_sprited.size() > 0:
		%ConfirmationDialog.text = "Currently this image is being used by" + str(checked_sprited.size()) + "sprites. Deleting it will add a Placeholder.(Can be Replaced later)"
		%ConfirmationDialog.popup()
	else:
		pass

func check_sprites():
	checked_sprited.clear()
	for sprite in get_tree().get_nodes_in_group("Sprites"):

			checked_sprited.append(sprite)

func _on_confirmation_dialog_canceled() -> void:
	%ConfirmationDialog.hide()
	checked_sprited.clear()

func _on_confirmation_dialog_confirmed() -> void:
	for sprite in checked_sprited:
		
		'''
		if sprite.referenced_data == ImageManagerFile.selected.image_data:
			sprite.get_node("%Sprite2D").texture.diffuse_texture = Global.image_data.runtime_texture
			sprite.used_image_id = 0
			sprite.referenced_data = Global.image_data
		if sprite.referenced_data_normal == ImageManagerFile.selected.image_data:
			sprite.get_node("%Sprite2D").texture.normal_texture = Global.image_data_normal.runtime_texture
			sprite.used_image_id_normal = 0
			sprite.referenced_data_normal = Global.image_data_normal
		ImageTrimmer.set_thumbnail(sprite.treeitem)
		'''
	held_button = null

func _on_tree_multi_selected(_item: TreeItem, _column: int, _selected: bool) -> void:
	held_items_assets.clear()
	await  get_tree().physics_frame
	for i in %Tree.get_root().get_child(0).get_children():
		if i.is_selected(0):
			held_items_assets.append(i)

func check_type(path, image_data):
	var apng_test = AImgIOAPNGImporter.load_from_file(path)
	if path.get_extension() == "gif":
		SaveAndLoad.import_gif(path, image_data)
	elif apng_test != ["No frames", null]:
		SaveAndLoad.import_apng_sprite(path, image_data)
	else:
		SaveAndLoad.import_png_from_file(path, null, image_data)
	Global.image_manager_data.append(image_data)
	Global.add_new_image.emit(image_data)

func _on_offset_sprite_toggled(toggled_on: bool) -> void:
	SaveAndLoad.should_offset = toggled_on

func _on_confirm_trim_confirmed() -> void:
	SaveAndLoad.trim = true
	for path in paths_placeholder:
		var new_image : ImageData = ImageData.new()
		check_type(path, new_image)
	paths_placeholder = []

func _on_confirm_trim_canceled() -> void:
	SaveAndLoad.trim = false
	for path in paths_placeholder:
		var new_image : ImageData = ImageData.new()
		check_type(path, new_image)
	paths_placeholder = []

func _on_file_dialog_files_selected(paths: PackedStringArray) -> void:
	paths_placeholder = paths
	%ConfirmTrim.popup()
