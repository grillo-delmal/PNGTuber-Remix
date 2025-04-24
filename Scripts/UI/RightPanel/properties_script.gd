extends Node


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
	%AnimationReset.disabled = true
	%AnimationOneShot.disabled = true
	%ResetonStateChange.disabled = true
	%RSSlider.editable = false

func enable():
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
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
		%AnimationOneShot.disabled = false
		%AnimationReset.disabled = false
		%ResetonStateChange.disabled = false
		%RSSlider.editable = true
		
		set_data()

func set_data():
	%RSSlider.value = Global.held_sprite.sprite_data.rainbow_speed
	%ColorPickerButton.color = Global.held_sprite.sprite_data.colored
	%TintPickerButton.color = Global.held_sprite.sprite_data.tint
	%Visible.button_pressed = Global.held_sprite.sprite_data.visible
	%ZOrderSpinbox.value = Global.held_sprite.sprite_data.z_index
	%SizeSpinBox.value = Global.held_sprite.sprite_data.scale.x
	%SizeSpinYBox.value = Global.held_sprite.sprite_data.scale.y
	
	if Global.held_sprite.get_node("%Sprite2D").get_clip_children_mode() == 0:
		%ClipChildren.button_pressed = false
	else:
		%ClipChildren.button_pressed = true
		
	%BlendMode.text = Global.held_sprite.sprite_data.blend_mode
	%OffsetXSpinBox.value = Global.held_sprite.sprite_data.offset.x
	%OffsetYSpinBox.value = Global.held_sprite.sprite_data.offset.y
	
	%PosXSpinBox.value = Global.held_sprite.sprite_data.position.x
	%PosYSpinBox.value = Global.held_sprite.sprite_data.position.y
	%RotSpinBox.value = Global.held_sprite.sprite_data.rotation / 0.01745
	
	if !%PosXSpinBox.value_changed.is_connected(_on_pos_x_spin_box_value_changed):
		%PosXSpinBox.value_changed.connect(_on_pos_x_spin_box_value_changed)
		%PosYSpinBox.value_changed.connect(_on_pos_y_spin_box_value_changed)
		%RotSpinBox.value_changed.connect(_on_rot_spin_box_value_changed)
	
	if Global.held_sprite.sprite_data.should_blink:
		if Global.held_sprite.sprite_data.open_eyes:
			%EyeOption.select(1)
		else:
			%EyeOption.select(2)
	else:
		%EyeOption.select(0)
	
	if Global.held_sprite.sprite_data.should_talk:
		if Global.held_sprite.sprite_data.open_mouth:
			%MouthOption.select(1)
		else:
			%MouthOption.select(2)
	else:
		%MouthOption.select(0)
	
	if Global.held_sprite.sprite_type == "Sprite2D":
		%FlipSpriteH.button_pressed = Global.held_sprite.sprite_data.flip_sprite_h
		%FlipSpriteV.button_pressed = Global.held_sprite.sprite_data.flip_sprite_v
	
	elif Global.held_sprite.sprite_type == "WiggleApp":
		%FlipSpriteH.button_pressed = Global.held_sprite.sprite_data.flip_h
		%FlipSpriteV.button_pressed = Global.held_sprite.sprite_data.flip_v

	%AnimationReset.button_pressed = Global.held_sprite.sprite_data.should_reset
	%AnimationOneShot.button_pressed = Global.held_sprite.sprite_data.one_shot
	%ResetonStateChange.button_pressed = Global.held_sprite.sprite_data.should_reset_state
	

func _on_blend_state_pressed(id):
	if Global.held_sprite:
		match id:
			0:
				Global.held_sprite.sprite_data.blend_mode = "Normal"
			1:
				Global.held_sprite.sprite_data.blend_mode = "Add"
			2:
				Global.held_sprite.sprite_data.blend_mode = "Subtract"
			3:
				Global.held_sprite.sprite_data.blend_mode = "Multiply"
				
			4:
				Global.held_sprite.sprite_data.blend_mode = "Burn"
				
			5:
				Global.held_sprite.sprite_data.blend_mode = "HardMix"
				
			6:
				Global.held_sprite.sprite_data.blend_mode = "Cursed"
		%BlendMode.text = Global.held_sprite.sprite_data.blend_mode
		Global.held_sprite.set_blend(Global.held_sprite.sprite_data.blend_mode)
		Global.held_sprite.save_state(Global.current_state)

func update_pos_spins():
	%PosXSpinBox.value = Global.held_sprite.position.x
	%PosYSpinBox.value = Global.held_sprite.position.y
	%RotSpinBox.value = Global.held_sprite.rotation / 0.01745
	Global.held_sprite.save_state(Global.current_state)

func update_offset():
	%OffsetXSpinBox.value = Global.held_sprite.sprite_data.offset.x
	%OffsetYSpinBox.value = Global.held_sprite.sprite_data.offset.y
	update_pos_spins()

func _on_color_picker_button_color_changed(color: Color) -> void:
	Global.held_sprite.modulate = color
	Global.held_sprite.sprite_data.colored = color
	Global.held_sprite.save_state(Global.current_state)

func _on_color_picker_button_focus_entered() -> void:
	Global.spinbox_held = true

func _on_color_picker_button_focus_exited() -> void:
	Global.spinbox_held = false

func _on_tint_picker_button_color_changed(ncolor: Color) -> void:
	Global.held_sprite.sprite_data.tint = ncolor
	Global.held_sprite.get_node("%Sprite2D").self_modulate = ncolor
	Global.held_sprite.save_state(Global.current_state)

func _on_pos_x_spin_box_value_changed(value):
	if %PosXSpinBox.get_line_edit().has_focus():
		Global.held_sprite.sprite_data.position.x = value
		Global.held_sprite.position.x = value
		Global.held_sprite.save_state(Global.current_state)

func _on_pos_y_spin_box_value_changed(value):
	if %PosYSpinBox.get_line_edit().has_focus():
		Global.held_sprite.sprite_data.position.y = value
		Global.held_sprite.position.y = value
		Global.held_sprite.save_state(Global.current_state)

func _on_rot_spin_box_value_changed(value):
	Global.held_sprite.rotation = value * 0.01745
	Global.held_sprite.sprite_data.rotation = value * 0.01745
	Global.held_sprite.save_state(Global.current_state)

func _on_visible_toggled(toggled_on):
	if toggled_on:
		Global.held_sprite.sprite_data.visible = true
		Global.held_sprite.visible = true
		Global.held_sprite.treeitem.set_button(0, 0, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton.png"))
	else:
		Global.held_sprite.sprite_data.visible = false
		Global.held_sprite.visible = false
		Global.held_sprite.treeitem.set_button(0, 0, preload("res://UI/EditorUI/LeftUI/Components/LayerView/Assets/New folder/EyeButton2.png"))
	Global.held_sprite.save_state(Global.current_state)

func _on_z_order_spinbox_value_changed(value):
	Global.held_sprite.sprite_data.z_index = value
	Global.held_sprite.get_node("%Wobble").z_index = value
	Global.held_sprite.save_state(Global.current_state)

func _on_size_spin_y_box_value_changed(value):
	Global.held_sprite.sprite_data.scale.y = value
	Global.held_sprite.scale.y = value
	Global.held_sprite.save_state(Global.current_state)

func _on_size_spin_box_value_changed(value):
	Global.held_sprite.sprite_data.scale.x = value
	Global.held_sprite.scale.x = value
	Global.held_sprite.save_state(Global.current_state)

func _on_offset_y_spin_box_value_changed(value):
	if %OffsetYSpinBox.get_line_edit().has_focus():
		var of = Global.held_sprite.sprite_data.offset.y - value
		Global.held_sprite.sprite_data.position.y += of
		Global.held_sprite.position.y = Global.held_sprite.sprite_data.position.y
		
		Global.held_sprite.sprite_data.offset.y = value
		Global.held_sprite.get_node("%Sprite2D").position.y = Global.held_sprite.sprite_data.offset.y
		Global.held_sprite.save_state(Global.current_state)
		update_pos_spins()

func _on_offset_x_spin_box_value_changed(value):
	if %OffsetXSpinBox.get_line_edit().has_focus():
		var of = Global.held_sprite.sprite_data.offset.x - value
		Global.held_sprite.sprite_data.position.x += of
		Global.held_sprite.position.x = Global.held_sprite.sprite_data.position.x
		
		Global.held_sprite.sprite_data.offset.x = value
		Global.held_sprite.get_node("%Sprite2D").position.x = Global.held_sprite.sprite_data.offset.x
		Global.held_sprite.save_state(Global.current_state)
		update_pos_spins()

func _on_flip_sprite_h_toggled(toggled_on: bool) -> void:
	if Global.held_sprite.sprite_type == "Sprite2D":
		Global.held_sprite.sprite_data.flip_sprite_h = toggled_on
		Global.held_sprite.get_node("%Sprite2D").flip_h = toggled_on
		Global.held_sprite.save_state(Global.current_state)
	elif Global.held_sprite.sprite_type == "WiggleApp":
		Global.held_sprite.sprite_data.flip_h = toggled_on
		if Global.held_sprite.sprite_data.flip_h:
			Global.held_sprite.get_node("%AppendageFlip").scale.x = -1
		else:
			Global.held_sprite.get_node("%AppendageFlip").scale.x = 1
		Global.held_sprite.save_state(Global.current_state)

func _on_flip_sprite_v_toggled(toggled_on: bool) -> void:
	if Global.held_sprite.sprite_type == "Sprite2D":
		Global.held_sprite.sprite_data.flip_sprite_v = toggled_on
		Global.held_sprite.get_node("%Sprite2D").flip_v = toggled_on
		Global.held_sprite.save_state(Global.current_state)
		
	elif Global.held_sprite.sprite_type == "WiggleApp":
		Global.held_sprite.sprite_data.flip_v = toggled_on
		if Global.held_sprite.sprite_data.flip_v:
			Global.held_sprite.get_node("%AppendageFlip").scale.y = -1
		else:
			Global.held_sprite.get_node("%AppendageFlip").scale.y = 1
		Global.held_sprite.save_state(Global.current_state)

func _on_clip_children_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Global.held_sprite.get_node("%Sprite2D").set_clip_children_mode(2)
		Global.held_sprite.sprite_data.clip = 2
	else:
		Global.held_sprite.get_node("%Sprite2D").set_clip_children_mode(0)
		Global.held_sprite.sprite_data.clip = 0
	Global.held_sprite.save_state(Global.current_state)

func _on_eye_option_item_selected(index: int) -> void:
	match index:
		0:
			Global.held_sprite.sprite_data.should_blink = false
		1:
			Global.held_sprite.sprite_data.should_blink = true
			Global.held_sprite.sprite_data.open_eyes = true
		2:
			Global.held_sprite.sprite_data.should_blink = true
			Global.held_sprite.sprite_data.open_eyes = false
	Global.blink.emit()

func _on_mouth_option_item_selected(index: int) -> void:
	match index:
		0:
			Global.held_sprite.sprite_data.should_talk = false
		1:
			Global.held_sprite.sprite_data.should_talk = true
			Global.held_sprite.sprite_data.open_mouth = true
		2:
			Global.held_sprite.sprite_data.should_talk = true
			Global.held_sprite.sprite_data.open_mouth = false
	Global.not_speaking.emit()

func _on_animation_reset_toggled(toggled_on):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.should_reset = toggled_on
		Global.held_sprite.save_state(Global.current_state)

func _on_animation_one_shot_toggled(toggled_on):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.one_shot = toggled_on
		Global.held_sprite.get_node("%AnimatedSpriteTexture").played_once = false
		if Global.held_sprite.img_animated:
			Global.held_sprite.get_node("%Sprite2D").texture.diffuse_texture.one_shot = toggled_on
			if Global.held_sprite.get_node("%Sprite2D").texture.normal_texture != null:
				Global.held_sprite.get_node("%Sprite2D").texture.normal_texture.one_shot = toggled_on
		Global.held_sprite.save_state(Global.current_state)

func _on_rs_slider_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		%RSLabel.text = "Rainbow Speed : " + str(snapped(value, 0.001))
		Global.held_sprite.sprite_data.rainbow_speed = value
		Global.held_sprite.save_state(Global.current_state)


func _on_reseton_state_change_toggled(toggled_on: bool) -> void:
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.should_reset_state = toggled_on
		Global.held_sprite.save_state(Global.current_state)
