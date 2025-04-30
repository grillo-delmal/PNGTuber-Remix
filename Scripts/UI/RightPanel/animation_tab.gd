extends Control

var should_change : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()

func nullfy():
	%AnimationReset.disabled = true
	%AnimationOneShot.disabled = true
	%ResetonStateChange.disabled = true
	%RSSlider.editable = false

func enable():
	for i in Global.held_sprites:
		if i != null && is_instance_valid(i):
			%AnimationOneShot.disabled = false
			%AnimationReset.disabled = false
			%ResetonStateChange.disabled = false
			%RSSlider.editable = true
			
			set_data()

func set_data():
	should_change = false
	for i in Global.held_sprites:
		%AnimationReset.button_pressed = i.sprite_data.should_reset
		%AnimationOneShot.button_pressed = i.sprite_data.one_shot
		%ResetonStateChange.button_pressed = i.sprite_data.should_reset_state
		%RSSlider.value = i.sprite_data.rainbow_speed

	should_change = true


func _on_animation_reset_toggled(toggled_on):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.should_reset = toggled_on
				i.save_state(Global.current_state)

func _on_animation_one_shot_toggled(toggled_on):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.one_shot = toggled_on
				i.get_node("%AnimatedSpriteTexture").played_once = false
				if i.img_animated:
					i.get_node("%Sprite2D").texture.diffuse_texture.one_shot = toggled_on
					if i.get_node("%Sprite2D").texture.normal_texture != null:
						i.get_node("%Sprite2D").texture.normal_texture.one_shot = toggled_on
				i.save_state(Global.current_state)


func _on_reseton_state_change_toggled(toggled_on: bool) -> void:
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				i.sprite_data.should_reset_state = toggled_on
				i.save_state(Global.current_state)


func _on_rs_slider_value_changed(value):
	if should_change:
		for i in Global.held_sprites:
			if i != null && is_instance_valid(i):
				%RSLabel.text = "Rainbow Speed : " + str(snapped(value, 0.001))
				i.sprite_data.rainbow_speed = value
				i.save_state(Global.current_state)
