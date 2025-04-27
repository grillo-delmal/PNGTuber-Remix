extends Node

var append_folder_selected : bool = false
var should_change : bool = false

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
	append_folder_selected = false
	should_change = false
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			if !i.sprite_data.advanced_lipsync:
				if i.sprite_type == "Sprite2D":
					if !append_folder_selected:
						%AnimationFramesSlider.editable = true
						%AnimationFramesSlider2.editable = true
						%AnimationSpeedSlider.editable = true
				else:
					%AnimationFramesSlider.editable = false
					%AnimationFramesSlider2.editable = false
					%AnimationSpeedSlider.editable = false
					append_folder_selected = true
			else:
				%AnimationFramesSlider.editable = false
				%AnimationFramesSlider2.editable = false
				%AnimationSpeedSlider.editable = false
			#	append_folder_selected = true
				
			if i.sprite_type == "Sprite2D" && !append_folder_selected:
				%AnimationFramesSlider.value = i.sprite_data.hframes
				%AnimationFramesSlider2.value = i.sprite_data.vframes
				%AnimationSpeedSlider.value = i.sprite_data.animation_speed
			
		if not Global.held_sprites[0].sprite_data.folder:
			%CurrentSelectedNormal.texture = Global.held_sprites[0].get_node("%Sprite2D").texture.normal_texture
			%CurrentSelected.texture = Global.held_sprites[0].get_node("%Sprite2D").texture.diffuse_texture
			append_folder_selected = true
		else:
			%CurrentSelected.texture = null
			%CurrentSelectedNormal.texture = null
	should_change = true

func _on_animation_frames_slider_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				if i != null && is_instance_valid(i):
					%AnimationFramesLabel.text = "Animation frames H : " + str(value)
					i.sprite_data.hframes = value
					i.animation()
					i.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
					i.save_state(Global.current_state)

func _on_animation_speed_slider_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				if i != null && is_instance_valid(i):
					%AnimationSpeedLabel.text = "Animation Speed : " + str(value) + " Fps"
					i.sprite_data.animation_speed = value
					i.animation()
					i.save_state(Global.current_state)


func _on_animation_frames_slider_2_value_changed(value: float) -> void:
	if should_change:
		for i in Global.held_sprites:
			if i.sprite_type == "Sprite2D":
				if i != null && is_instance_valid(i):
					%AnimationFramesLabel2.text = "Animation frames V : " + str(value)
					i.sprite_data.vframes = value
					i.animation()
					i.get_node("%Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
					i.save_state(Global.current_state)
