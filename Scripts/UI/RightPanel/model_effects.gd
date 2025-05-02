extends VBoxContainer


func _ready() -> void:
	Global.reinfoanim.connect(set_data)

func set_data():
	if Global.sprite_container != null && is_instance_valid(Global.sprite_container):
		%EffectType.select(Global.sprite_container.model_effects.effect_type)
		%EffectColor.color = Global.sprite_container.model_effects.effect_color
		%SizeSlider.value = Global.sprite_container.model_effects.effect_size
	#	%RainbowCheck

func _on_option_button_item_selected(index: int) -> void:
	Global.viewer.material.set_shader_parameter("effect", index)
	Global.sprite_container.model_effects.effect_type = index
	Global.sprite_container.save_state(Global.current_state)


func _on_effect_color_color_changed(color: Color) -> void:
	Global.viewer.material.set_shader_parameter("line_color", color)
	Global.sprite_container.model_effects.effect_color = color
	Global.sprite_container.save_state(Global.current_state)


func _on_size_slider_value_changed(value: float) -> void:
	Global.viewer.material.set_shader_parameter("line_scale", value)
	Global.sprite_container.model_effects.effect_size = value
	Global.sprite_container.save_state(Global.current_state)


func _on_rainbow_check_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_color_blindness_helper_options_item_selected(index: int) -> void:
	Global.viewport.material.set_shader_parameter("effect", index)
