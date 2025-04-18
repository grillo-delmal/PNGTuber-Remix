extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()


func nullfy():
	%AnimationFramesSlider.editable = false
	%AnimationFramesSlider2.editable = false
	%AnimationSpeedSlider.editable = false
	%CurrentSelected.texture = null
	%CurrentSelectedNormal.texture = null
	

func enable():
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if not Global.held_sprite.sprite_data.advanced_lipsync:
			if Global.held_sprite.sprite_type == "Sprite2D" && not Global.held_sprite.img_animated:
				%AnimationFramesSlider.editable = true
				%AnimationFramesSlider2.editable = true
				%AnimationSpeedSlider.editable = true
		else:
			%AnimationFramesSlider.editable = false
			%AnimationFramesSlider2.editable = false
			%AnimationSpeedSlider.editable = false
			
		if Global.held_sprite.sprite_type == "Sprite2D":
			%AnimationFramesSlider.value = Global.held_sprite.sprite_data.hframes
			%AnimationFramesSlider2.value = Global.held_sprite.sprite_data.vframes
			%AnimationSpeedSlider.value = Global.held_sprite.sprite_data.animation_speed
		
		if not Global.held_sprite.sprite_data.folder:
			
			%CurrentSelectedNormal.texture = Global.held_sprite.get_node("%Sprite2D").texture.normal_texture
			%CurrentSelected.texture = Global.held_sprite.get_node("%Sprite2D").texture.diffuse_texture
		else:
			%CurrentSelected.texture = null
			%CurrentSelectedNormal.texture = null

func _on_animation_frames_slider_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		%AnimationFramesLabel.text = "Animation frames H : " + str(value)
		Global.held_sprite.sprite_data.hframes = value
		Global.held_sprite.animation()
		Global.held_sprite.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		Global.held_sprite.save_state(Global.current_state)

func _on_animation_speed_slider_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		%AnimationSpeedLabel.text = "Animation Speed : " + str(value) + " Fps"
		Global.held_sprite.sprite_data.animation_speed = value
		Global.held_sprite.animation()
		Global.held_sprite.save_state(Global.current_state)


func _on_animation_frames_slider_2_value_changed(value: float) -> void:
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		%AnimationFramesLabel2.text = "Animation frames V : " + str(value)
		Global.held_sprite.sprite_data.vframes = value
		Global.held_sprite.animation()
		Global.held_sprite.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		Global.held_sprite.save_state(Global.current_state)
