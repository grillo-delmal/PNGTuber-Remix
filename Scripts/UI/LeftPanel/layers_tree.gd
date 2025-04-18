extends Tree

var held_item : TreeItem = null


func _get_drag_data(_at_position: Vector2) -> Variant:
	drop_mode_flags = 3
	if held_item == null:
		held_item = get_selected()
		return held_item
	else:
		return held_item
#	else:
	#	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is TreeItem

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data != null && is_instance_valid(data):
		if data is TreeItem:
			var other = get_item_at_position(at_position)
			if other != null && is_instance_valid(other):
				if other is TreeItem:
					move_stuff(data, other, at_position)
	drop_mode_flags = 3

func move_stuff(item : TreeItem, other_item : TreeItem, at_position):
	var true_pos = get_drop_section_at_position(at_position)
	var items = get_all_layeritems(item, true)
	
	if other_item in items:
		print("can't drop")
		held_item = null
		return
	
	if other_item == item:
		print("can't drop")
		held_item = null
		return
	
	#print(true_pos)
	var og_pos = item.get_metadata(0).sprite_object.global_position
	print(true_pos)
	if true_pos == 0:
		item.get_parent().remove_child(item)
		other_item.add_child(item)
		if other_item == get_root():
			item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
			item.get_metadata(0).sprite_object.parent_id = 0
			Global.sprite_container.add_child(item.get_metadata(0).sprite_object)
		else:
			item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
			other_item.get_metadata(0).sprite_object.get_node("%Sprite2D").add_child(item.get_metadata(0).sprite_object)
			item.get_metadata(0).sprite_object.parent_id = other_item.get_metadata(0).sprite_object.sprite_id
		item.get_metadata(0).sprite_object.global_position = og_pos
		item.get_metadata(0).sprite_object.sprite_data.position = item.get_metadata(0).sprite_object.position
		item.get_metadata(0).sprite_object.save_state(Global.current_state)
		
	elif true_pos == -1:
		if other_item.get_parent() != item.get_parent():
			if other_item.get_parent() == get_root():
				item.get_metadata(0).sprite_object.parent_id = 0
				item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
				Global.sprite_container.add_child(item.get_metadata(0).sprite_object)
			else:
				if other_item == get_root():
					item.get_metadata(0).sprite_object.parent_id = 0
					item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
					Global.sprite_container.add_child(item.get_metadata(0).sprite_object)
					item.get_metadata(0).sprite_object.get_parent().move_child(item.get_metadata(0).sprite_object,item.get_index())
				else:
					item.move_before(other_item)
					item.get_metadata(0).sprite_object.parent_id = other_item.get_metadata(0).sprite_object.parent_id
					item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
					other_item.get_metadata(0).sprite_object.get_parent().add_child(item.get_metadata(0).sprite_object)
					item.get_metadata(0).sprite_object.get_parent().move_child(item.get_metadata(0).sprite_object,item.get_index())
				
			item.get_metadata(0).sprite_object.global_position = og_pos
			item.get_metadata(0).sprite_object.sprite_data.position = item.get_metadata(0).sprite_object.position
			item.get_metadata(0).sprite_object.save_state(Global.current_state)
		else:
			item.move_before(other_item)
			item.get_metadata(0).sprite_object.get_parent().move_child(item.get_metadata(0).sprite_object,item.get_index())

	elif true_pos == 1:
		if other_item.get_parent() != item.get_parent():
			if other_item.get_parent() == get_root():
				item.get_metadata(0).sprite_object.parent_id = 0
				item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
				Global.sprite_container.add_child(item.get_metadata(0).sprite_object)
				
			else:
				if other_item == get_root():
					item.get_metadata(0).sprite_object.parent_id = 0
					item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
					Global.sprite_container.add_child(item.get_metadata(0).sprite_object)
					item.get_metadata(0).sprite_object.get_parent().move_child(item.get_metadata(0).sprite_object, clamp(item.get_index(), 0, item.get_metadata(0).sprite_object.get_parent().get_child_count() - 1))
				else:
					item.move_after(other_item)
					item.get_metadata(0).sprite_object.parent_id = other_item.get_metadata(0).sprite_object.parent_id
					item.get_metadata(0).sprite_object.get_parent().remove_child(item.get_metadata(0).sprite_object)
					other_item.get_metadata(0).sprite_object.get_parent().add_child(item.get_metadata(0).sprite_object)
					item.get_metadata(0).sprite_object.get_parent().move_child(item.get_metadata(0).sprite_object, clamp(item.get_index()+1, 0, item.get_metadata(0).sprite_object.get_parent().get_child_count() - 1))
			item.get_metadata(0).sprite_object.global_position = og_pos
			item.get_metadata(0).sprite_object.sprite_data.position = item.get_metadata(0).sprite_object.position
			item.get_metadata(0).sprite_object.save_state(Global.current_state)
				
		else:
			item.move_after(other_item)
			var count = item.get_metadata(0).sprite_object.get_parent().get_child_count() - 1
			item.get_metadata(0).sprite_object.get_parent().move_child(item.get_metadata(0).sprite_object, clamp(other_item.get_metadata(0).sprite_object.get_index()+1, 0, count))
	held_item = null

func get_all_layeritems(layeritem, recursive) -> Array:
	var children := []
	for child in layeritem.get_children():
		children.append(child)
		
		if recursive and child.get_child_count():
			children.append_array(get_all_layeritems(child, true))
		
	return children
