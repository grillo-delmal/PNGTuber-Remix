extends Node

var should_change : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%ColorPickerButton.get_picker().picker_shape = 1
	%ColorPickerButton.get_picker().presets_visible = false
	%ColorPickerButton.get_picker().color_modes_visible = false
	%BlendMode.get_popup().id_pressed.connect(_on_blend_state_pressed)
	
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	Global.update_offset_spins.connect(update_offset)
	Global.update_pos_spins.connect(update_pos_spins)
	nullfy()

func nullfy():
	if %PosXSpinBox.value_changed.is_connected(_on_pos_x_spin_box_value_changed):
		%PosXSpinBox.value_changed.disconnect(_on_pos_x_spin_box_value_changed)
		%PosYSpinBox.value_changed.disconnect(_on_pos_y_spin_box_value_changed)
		%RotSpinBox.value_changed.disconnect(_on_rot_spin_box_value_changed)
	%TintPickerButton.disabled = true
	%ColorPickerButton.disabled = true

	%EyeOption.disabled = true
	%MouthOption.disabled = true
	%SizeSpinBox.editable = false
	%SizeSpinYBox.editable = false

	%PosXSpinBox.editable = false
	%PosYSpinBox.editable = false
	%RotSpinBox.editable = false
	%RotSpinBox.editable = false
	%BlendMode.disabled = true
	%ClipChildren.disabled = true
	%Visible.disabled = true
	%ZOrderSpinbox.editable = false

	%OffsetXSpinBox.editable = false
	%OffsetYSpinBox.editable = false
	%FlipSpriteH.disabled = true
	%FlipSpriteV.disabled = true

func enable():
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			%TintPickerButton.disabled = false
			%ColorPickerButton.disabled = false
			%EyeOption.disabled = false
			%MouthOption.disabled = false
			%SizeSpinBox.editable = true
			%SizeSpinYBox.editable = true

			%PosXSpinBox.editable = true
			%PosYSpinBox.editable = true
			%RotSpinBox.editable = true
			%RotSpinBox.editable = true
			%BlendMode.disabled = false
			%ClipChildren.disabled = false
			%Visible.disabled = false
			%ZOrderSpinbox.editable = true
			%EyeOption.disabled = false
			%MouthOption.disabled = false
			
			%OffsetXSpinBox.editable = true
			%OffsetYSpinBox.editable = true
			%FlipSpriteH.disabled = false
			%FlipSpriteV.disabled = false
			
			set_data()

func set_data():
	should_change = false
	for i in Global.held_sprites:
		%ColorPickerButton.color = i.sprite_data.colored
		%TintPickerButton.color = i.sprite_data.tint
		%Visible.button_pressed = i.sprite_data.visible
		%ZOrderSpinbox.value = i.sprite_data.z_index
		%SizeSpinBox.value = i.sprite_data.scale.x
		%SizeSpinYBox.value = i.sprite_data.scale.y
		
		if i.get_node("%Sprite2D").get_clip_children_mode() == 0:
			%ClipChildren.button_pressed = false
		else:
			%ClipChildren.button_pressed = true
			
		%BlendMode.text = i.sprite_data.blend_mode
		%OffsetXSpinBox.value = i.sprite_data.offset.x
		%OffsetYSpinBox.value = i.sprite_data.offset.y
		
		%PosXSpinBox.value = i.sprite_data.position.x
		%PosYSpinBox.value = i.sprite_data.position.y
		%RotSpinBox.value = i.sprite_data.rotation / 0.01745
		
		if !%PosXSpinBox.value_changed.is_connected(_on_pos_x_spin_box_value_changed):
			%PosXSpinBox.value_changed.connect(_on_pos_x_spin_box_value_changed)
			%PosYSpinBox.value_changed.connect(_on_pos_y_spin_box_value_changed)
			%RotSpinBox.value_changed.connect(_on_rot_spin_box_value_changed)
		
		if i.sprite_data.should_blink:
			if i.sprite_data.open_eyes:
				%EyeOption.select(1)
			else:
				%EyeOption.select(2)
		else:
			%EyeOption.select(0)
		
		if i.sprite_data.should_talk:
			if i.sprite_data.open_mouth:
				%MouthOption.select(1)
			else:
				%MouthOption.select(2)
		else:
			%MouthOption.select(0)
		
		if i.sprite_type == "Sprite2D":
			%FlipSpriteH.button_pressed = i.sprite_data.flip_sprite_h
			%FlipSpriteV.button_pressed = i.sprite_data.flip_sprite_v
		
		elif i.sprite_type == "WiggleApp":
			%FlipSpriteH.button_pressed = i.sprite_data.flip_h
			%FlipSpriteV.button_pressed = i.sprite_data.flip_v

		
	should_change = true

func _on_blend_state_pressed(id):
	for i in Global.held_sprites:
		match id:
			0:
				i.sprite_data.blend_mode = "Normal"
			1:
				i.sprite_data.blend_mode = "Add"
			2:
				i.sprite_data.blend_mode = "Subtract"
			3:
				i.sprite_data.blend_mode = "Multiply"
				
			4:
				i.sprite_data.blend_mode = "Burn"
				
			5:
				i.sprite_data.blend_mode = "HardMix"
				
			6:
				i.sprite_data.blend_mode = "Cursed"
		%BlendMode.text = i.sprite_data.blend_mode
		i.set_blend(i.sprite_data.blend_mode)
		i.save_state(Global.current_state)

func update_pos_spins():
	for i in Global.held_sprites:
		%PosXSpinBox.value = i.position.x
		%PosYSpinBox.value = i.position.y
		%RotSpinBox.value = i.rotation / 0.01745
		i.save_state(Global.current_state)

func update_offset():
	for i in Global.held_sprites:
		%OffsetXSpinBox.value = i.sprite_data.offset.x
		%OffsetYSpinBox.value = i.sprite_data.offset.y
		update_pos_spins()

func _on_color_picker_button_color_changed(color: Color) -> void:
	if should_change:
		for i in Global.held_sprites:
			i.modulate = color
			i.sprite_data.colored = color
			i.save_state(Global.current_state)

func _on_color_picker_button_focus_entered() -> void:
	Global.spinbox_held = true

func _on_color_picker_button_focus_exited() -> void:
	Global.spinbox_held = false

func _on_tint_picker_button_color_changed(ncolor: Color) -> void:
	if should_change:
		for i in Global.held_sprites:
			i.sprite_data.tint = ncolor
			i.get_node("%Sprite2D").self_modulate = ncolor
			i.save_state(Global.current_state)

func _on_pos_x_spin_box_value_changed(value):
	if %PosXSpinBox.get_line_edit().has_focus():
		if should_change:
			for i in Global.held_sprites:
				i.sprite_data.position.x = value
				i.position.x = value
				i.save_state(Global.current_state)

func _on_pos_y_spin_box_value_changed(value):
	if %PosYSpinBox.get_line_edit().has_focus():
		if should_change:
			for i in Global.held_sprites:
				i.sprite_data.position.y = value
				i.position.y = value
				i.save_state(Global.current_state)

func _on_rot_spin_box_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			i.rotation = value * 0.01745
			i.sprite_data.rotation = value * 0.01745
			i.save_state(Global.current_state)

func _on_visible_toggled(toggled_on):
	if should_change:
		for i in Global.held_sprites:
			if toggled_on:
				i.sprite_data.visible = true
				i.visible = true
				i.treeitem.set_button(0, 0, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton.png"))
			else:
				i.sprite_data.visible = false
				i.visible = false
				i.treeitem.set_button(0, 0, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton2.png"))
			i.save_state(Global.current_state)

func _on_z_order_spinbox_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			i.sprite_data.z_index = value
			i.get_node("%Wobble").z_index = value
			i.save_state(Global.current_state)

func _on_size_spin_y_box_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			i.sprite_data.scale.y = value
			i.scale.y = value
			i.save_state(Global.current_state)

func _on_size_spin_box_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			i.sprite_data.scale.x = value
			i.scale.x = value
			i.save_state(Global.current_state)

func _on_offset_y_spin_box_value_changed(value):
	if %OffsetYSpinBox.get_line_edit().has_focus():
		if should_change:
			for i in Global.held_sprites:
				var of = i.sprite_data.offset.y - value
				i.sprite_data.position.y += of
				i.position.y = i.sprite_data.position.y
				
				i.sprite_data.offset.y = value
				i.get_node("%Sprite2D").position.y = i.sprite_data.offset.y
				i.save_state(Global.current_state)
				update_pos_spins()

func _on_offset_x_spin_box_value_changed(value):
	if %OffsetXSpinBox.get_line_edit().has_focus():
		if should_change:
			for i in Global.held_sprites:
				var of = i.sprite_data.offset.x - value
				i.sprite_data.position.x += of
				i.position.x = i.sprite_data.position.x
				
				i.sprite_data.offset.x = value
				i.get_node("%Sprite2D").position.x = i.sprite_data.offset.x
				i.save_state(Global.current_state)
			update_pos_spins()

func _on_flip_sprite_h_toggled(toggled_on: bool) -> void:
	if should_change:
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				i.sprite_data.flip_sprite_h = toggled_on
				i.get_node("%Sprite2D").flip_h = toggled_on
				i.save_state(Global.current_state)
			elif i.sprite_type == "WiggleApp":
				i.sprite_data.flip_h = toggled_on
				if i.sprite_data.flip_h:
					i.get_node("%AppendageFlip").scale.x = -1
				else:
					i.get_node("%AppendageFlip").scale.x = 1
				i.save_state(Global.current_state)

func _on_flip_sprite_v_toggled(toggled_on: bool) -> void:
	if should_change:
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				i.sprite_data.flip_sprite_v = toggled_on
				i.get_node("%Sprite2D").flip_v = toggled_on
				i.save_state(Global.current_state)
				
			elif i.sprite_type == "WiggleApp":
				i.sprite_data.flip_v = toggled_on
				if i.sprite_data.flip_v:
					i.get_node("%AppendageFlip").scale.y = -1
				else:
					i.get_node("%AppendageFlip").scale.y = 1
				i.save_state(Global.current_state)

func _on_clip_children_toggled(toggled_on: bool) -> void:
	if should_change:
		for i in Global.held_sprites:
			if toggled_on:
				i.get_node("%Sprite2D").set_clip_children_mode(2)
				i.sprite_data.clip = 2
			else:
				i.get_node("%Sprite2D").set_clip_children_mode(0)
				i.sprite_data.clip = 0
			i.save_state(Global.current_state)

func _on_eye_option_item_selected(index: int) -> void:
	if should_change:
		for i in Global.held_sprites:
			match index:
				0:
					i.sprite_data.should_blink = false
				1:
					i.sprite_data.should_blink = true
					i.sprite_data.open_eyes = true
				2:
					i.sprite_data.should_blink = true
					i.sprite_data.open_eyes = false
		Global.blink.emit()

func _on_mouth_option_item_selected(index: int) -> void:
	if should_change:
		for i in Global.held_sprites:
			match index:
				0:
					i.sprite_data.should_talk = false
				1:
					i.sprite_data.should_talk = true
					i.sprite_data.open_mouth = true
				2:
					i.sprite_data.should_talk = true
					i.sprite_data.open_mouth = false
		Global.not_speaking.emit()
