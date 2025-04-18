extends Node


func _ready():
	Global.light_info.connect(get_info)
	%LightColor.get_picker().picker_shape = 1
	%LightColor.get_picker().presets_visible = false
	%LightColor.get_picker().color_modes_visible = false
	%LightEnergyBSlider.get_node("SliderValue").value_changed.connect(_on_light_energy_slider_value_changed)
	%LightSizeBSlider.get_node("SliderValue").value_changed.connect(_on_light_size_slider_value_changed)

func _on_light_energy_slider_value_changed(value):
	if Global.light != null && is_instance_valid(Global.light):
		Global.light.energy = value
		Global.light.save_state(Global.current_state)


func _on_light_color_color_changed(color):
	if Global.light != null && is_instance_valid(Global.light):
		Global.light.color = color
		Global.light.save_state(Global.current_state)


func _on_light_source_vis_toggled(toggled_on):
	if Global.light != null && is_instance_valid(Global.light):
		Global.light.visible = toggled_on
		Global.light.save_state(Global.current_state)


func _on_ls_shape_vis_toggled(toggled_on):
	if Global.light != null && is_instance_valid(Global.light):
		Global.light.get_node("Grab").visible = toggled_on


func _on_light_size_slider_value_changed(value):
	if Global.light != null && is_instance_valid(Global.light):
		Global.light.scale = Vector2(value,value)
		Global.light.save_state(Global.current_state)


func get_info(state):
	if not Global.settings_dict.light_states[state].is_empty():
		var dict = Global.settings_dict.light_states[state]
		%LightSourceVis.button_pressed = dict.visible
		%LightColor.color = dict.color
		%LightEnergyBSlider.get_node("SliderValue").value = dict.energy
		%LightSizeBSlider.get_node("SliderValue").value = dict.scale.x
		%LightPosXSpinBox.value = Global.light.global_position.x
		%LightPosYSpinBox.value = Global.light.global_position.y
	%DarkenCheck.button_pressed = Global.settings_dict.darken
	%DarkenColor.color = Global.settings_dict.dim_color


func reset_info(light_source):
		%LightSourceVis.button_pressed = light_source.visible
		%LSShapeVis.button_pressed = false
		%LightColor.color = light_source.color
		%LightEnergyBSlider.get_node("SliderValue").value = light_source.energy
		%LightSizeBSlider.get_node("SliderValue").value = light_source.scale.x
		%LightPosXSpinBox.value = light_source.global_position.x
		%LightPosYSpinBox.value = light_source.global_position.y


func _on_darken_check_toggled(toggled_on):
	if Global.light != null && is_instance_valid(Global.light):
		Global.settings_dict.darken = toggled_on


func _on_light_pos_x_spin_box_value_changed(value):
	if Global.light != null && is_instance_valid(Global.light):
		Global.light.global_position.x = value
		Global.light.save_state(Global.current_state)


func _on_light_pos_y_spin_box_value_changed(value):
	if Global.light != null && is_instance_valid(Global.light):
		Global.light.global_position.y = value
		Global.light.save_state(Global.current_state)


func _on_darken_color_color_changed(color):
	if Global.light != null && is_instance_valid(Global.light):
		Global.settings_dict.dim_color = color
