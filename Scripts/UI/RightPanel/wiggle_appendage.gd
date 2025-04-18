extends Node


func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	nullfy()

func enable():
	nullfy()
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if Global.held_sprite.sprite_type == "WiggleApp":
			%WiggleWidthSpin.editable = true
			%WiggleLengthSpin.editable = true
			%WiggleSubDSpin.editable = true
			%WAGravityX.editable = true
			%WAGravityY.editable = true
			%ClosedLoopCheck.disabled = false
			%AutoWagCheck.disabled = false
		set_data()

func nullfy():
	%AutoWagCheck.disabled = true
	%WiggleWidthSpin.editable = false
	%WiggleLengthSpin.editable = false
	%WiggleSubDSpin.editable = false
	%WAGravityX.editable = false
	%WAGravityY.editable = false
	%ClosedLoopCheck.disabled = true

func set_data():
	if Global.held_sprite.sprite_type == "WiggleApp":
		%WiggleAppStuff.show()
		%WiggleWidthSpin.value = Global.held_sprite.sprite_data.width
		%WiggleLengthSpin.value = Global.held_sprite.sprite_data.segm_length
		%WiggleSubDSpin.value = Global.held_sprite.sprite_data.subdivision
		%WAGravityX.value = Global.held_sprite.sprite_data.wiggle_gravity.x
		%WAGravityY.value = Global.held_sprite.sprite_data.wiggle_gravity.y
		%ClosedLoopCheck.button_pressed = Global.held_sprite.sprite_data.wiggle_closed_loop
		%AutoWagCheck.button_pressed = Global.held_sprite.sprite_data.auto_wag
	else:
		%WiggleAppStuff.hide()

func _on_auto_wag_check_toggled(toggled_on):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.auto_wag = toggled_on
		if toggled_on:
			%AutoWagSettings.show()
			%WiggleAppsCurveBSlider.hide()
		if !toggled_on:
			Global.held_sprite.get_node("%Sprite2D").curvature = Global.held_sprite.sprite_data.wiggle_curve
			%AutoWagSettings.hide()
			%WiggleAppsCurveBSlider.show()
			
		Global.held_sprite.save_state(Global.current_state)

func _on_wa_gravity_x_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if Global.held_sprite.sprite_type == "WiggleApp":
			Global.held_sprite.sprite_data.wiggle_gravity.x = value
			Global.held_sprite.get_node("%Sprite2D").gravity.x = value
			Global.held_sprite.save_state(Global.current_state)

func _on_wa_gravity_y_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if Global.held_sprite.sprite_type == "WiggleApp":
			Global.held_sprite.sprite_data.wiggle_gravity.y = value
			Global.held_sprite.get_node("%Sprite2D").gravity.y = value
			Global.held_sprite.save_state(Global.current_state)

func _on_closed_loop_check_toggled(toggled_on):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if Global.held_sprite.sprite_type == "WiggleApp":
			Global.held_sprite.sprite_data.wiggle_closed_loop = toggled_on
			Global.held_sprite.get_node("%Sprite2D").closed = toggled_on
			Global.held_sprite.save_state(Global.current_state)

func _on_wiggle_width_spin_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.width = value
		Global.held_sprite.get_node("%Sprite2D").width = value
		Global.held_sprite.save_state(Global.current_state)

func _on_wiggle_length_spin_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.segm_length = value
		Global.held_sprite.get_node("%Sprite2D").segment_length = value
		Global.held_sprite.save_state(Global.current_state)

func _on_wiggle_sub_d_spin_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.subdivision = value
		Global.held_sprite.get_node("%Sprite2D").subdivision = value
		Global.held_sprite.save_state(Global.current_state)
