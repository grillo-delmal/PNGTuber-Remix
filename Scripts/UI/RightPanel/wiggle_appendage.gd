extends Node

var sprite_selected : bool = false
var should_change : bool = false


func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	nullfy()

func enable():
	nullfy()
	sprite_selected = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if i.sprite_type == "WiggleApp" && !sprite_selected:
				%WiggleWidthSpin.editable = true
				%WiggleLengthSpin.editable = true
				%WiggleSubDSpin.editable = true
				%WAGravityX.editable = true
				%WAGravityY.editable = true
				%ClosedLoopCheck.disabled = false
				%AutoWagCheck.disabled = false
				%TextureModeOption.disabled = false
			else:
				sprite_selected = true
				nullfy()
	
	set_data()

func nullfy():
	%AutoWagCheck.disabled = true
	%WiggleWidthSpin.editable = false
	%WiggleLengthSpin.editable = false
	%WiggleSubDSpin.editable = false
	%WAGravityX.editable = false
	%WAGravityY.editable = false
	%ClosedLoopCheck.disabled = true
	%TextureModeOption.disabled = true

func set_data():
	should_change = false
	if !sprite_selected:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "WiggleApp":
					%WiggleAppStuff.show()
					%WiggleWidthSpin.value = i.sprite_data.width
					%WiggleLengthSpin.value = i.sprite_data.segm_length
					%WiggleSubDSpin.value = i.sprite_data.subdivision
					%WAGravityX.value = i.sprite_data.wiggle_gravity.x
					%WAGravityY.value = i.sprite_data.wiggle_gravity.y
					%ClosedLoopCheck.button_pressed = i.sprite_data.wiggle_closed_loop
					%AutoWagCheck.button_pressed = i.sprite_data.auto_wag
					match i.sprite_data.tile:
						1:
							%TextureModeOption.select(1)
						2:
							%TextureModeOption.select(0)
	else:
		%WiggleAppStuff.hide()
	
	should_change = true

func _on_auto_wag_check_toggled(toggled_on):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.auto_wag = toggled_on
				if toggled_on:
					%AutoWagSettings.show()
					%WiggleAppsCurveBSlider.hide()
				if !toggled_on:
					i.get_node("%Sprite2D").curvature = i.sprite_data.wiggle_curve
					%AutoWagSettings.hide()
					%WiggleAppsCurveBSlider.show()
					
				i.save_state(Global.current_state)

func _on_wa_gravity_x_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "WiggleApp":
					i.sprite_data.wiggle_gravity.x = value
					i.get_node("%Sprite2D").gravity.x = value
					i.save_state(Global.current_state)

func _on_wa_gravity_y_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "WiggleApp":
					i.sprite_data.wiggle_gravity.y = value
					i.get_node("%Sprite2D").gravity.y = value
					i.save_state(Global.current_state)

func _on_closed_loop_check_toggled(toggled_on):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				if i.sprite_type == "WiggleApp":
					i.sprite_data.wiggle_closed_loop = toggled_on
					i.get_node("%Sprite2D").closed = toggled_on
					i.save_state(Global.current_state)

func _on_wiggle_width_spin_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.width = value
				i.get_node("%Sprite2D").width = value
				i.save_state(Global.current_state)

func _on_wiggle_length_spin_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.segm_length = value
				i.get_node("%Sprite2D").segment_length = value
				i.save_state(Global.current_state)

func _on_wiggle_sub_d_spin_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.subdivision = value
				i.get_node("%Sprite2D").subdivision = value
				i.save_state(Global.current_state)


func _on_texture_mode_option_item_selected(index: int) -> void:
	match index:
		0:
			if should_change:
				for i in Global.held_sprites:
					if i != null && is_instance_valid(i):
						i.sprite_data.tile = 2
						i.get_node("%Sprite2D").texture_mode = 2
						i.save_state(Global.current_state)
		1:
			if should_change:
				for i in Global.held_sprites:
					if i != null && is_instance_valid(i):
						i.sprite_data.tile = 1
						i.get_node("%Sprite2D").texture_mode = 1
						i.save_state(Global.current_state)
