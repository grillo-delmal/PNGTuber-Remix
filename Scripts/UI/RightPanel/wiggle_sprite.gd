extends Node


func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	nullfy()

func enable():
	nullfy()
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		%TipSpin.editable = true
		%FollowWiggleAppTip.disabled = false
		
		if Global.held_sprite.sprite_type == "Sprite2D":
			%WiggleCheck.disabled = false
			%FollowParentEffect.disabled = false
			%XoffsetSpinBox.editable = true
			%YoffsetSpinBox.editable = true
		else:
			%WiggleCheck.disabled = true
			%FollowParentEffect.disabled = true
			%XoffsetSpinBox.editable = false
			%YoffsetSpinBox.editable = false
		set_data()

func set_data():
	if Global.held_sprite.get_parent() is WigglyAppendage2D:
		%TipSpin.max_value = Global.held_sprite.get_parent().points.size() -1
		
	
	%TipSpin.value = Global.held_sprite.sprite_data.tip_point
	%FollowWiggleAppTip.button_pressed = Global.held_sprite.sprite_data.follow_wa_tip
	if Global.held_sprite.sprite_type == "Sprite2D":
		%WiggleStuff.show()
		%WiggleCheck.button_pressed = Global.held_sprite.sprite_data.wiggle
		%FollowParentEffect.button_pressed = Global.held_sprite.sprite_data.follow_parent_effects
		%XoffsetSpinBox.value = Global.held_sprite.sprite_data.wiggle_rot_offset.x
		%YoffsetSpinBox.value = Global.held_sprite.sprite_data.wiggle_rot_offset.y
	else:
		%WiggleStuff.hide()

func nullfy():
	%TipSpin.editable = false
	
	%WiggleCheck.disabled = true
	%FollowParentEffect.disabled = true
	%FollowWiggleAppTip.disabled = true
	%XoffsetSpinBox.editable = false
	%YoffsetSpinBox.editable = false

func _on_follow_wiggle_app_tip_toggled(toggled_on):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.follow_wa_tip = toggled_on
		if toggled_on:
			%TipSpin.editable = true
			%MiniFWBSlider.show()
			%MaxFWBSlider.show()
		if not toggled_on:
			%TipSpin.editable = false
			%MiniFWBSlider.hide()
			%MaxFWBSlider.hide()
			Global.held_sprite.get_node("Pos").position = Vector2(0,0)
		Global.held_sprite.save_state(Global.current_state)

func _on_tip_spin_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.tip_point = value
		Global.held_sprite.save_state(Global.current_state)

func _on_wiggle_check_toggled(toggled_on):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.wiggle = toggled_on
		Global.held_sprite.get_node("%Sprite2D").material.set_shader_parameter("wiggle", toggled_on)
		Global.held_sprite.save_state(Global.current_state)

func _on_follow_parent_effect_toggled(toggled_on):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.follow_parent_effects = toggled_on
		Global.held_sprite.save_state(Global.current_state)

func _on_xoffset_spin_box_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.wiggle_rot_offset.x = value
		Global.held_sprite.get_node("%Sprite2D").material.set_shader_parameter("rotation_offset", Vector2(value, Global.held_sprite.get_node("%Sprite2D").material.get_shader_parameter("rotation_offset").y))
		Global.held_sprite.save_state(Global.current_state)

func _on_yoffset_spin_box_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.wiggle_rot_offset.y = value
		Global.held_sprite.get_node("%Sprite2D").material.set_shader_parameter("rotation_offset", Vector2(Global.held_sprite.get_node("%Sprite2D").material.get_shader_parameter("rotation_offset").x, value))
		Global.held_sprite.save_state(Global.current_state)
