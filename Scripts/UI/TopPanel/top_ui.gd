extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().current_scene.ready
	sliders_revalue(Global.settings_dict)
	Global.reinfo.connect(info_held)
	Global.slider_values.connect(sliders_revalue)
	Global.deselect.connect(info_desel)
	%CreditLabel.text = "PNGTuber Remix by TheMime (MudkipWorld)
	Original PNGTuber+ Code by kaiakairos. Better UI by LeoRson.
	V" + str(ProjectSettings.get_setting("application/config/version"))

func info_held():
	%DeselectButton.show()

func info_desel():
	%DeselectButton.hide()

func sliders_revalue(settings_dict):
	%BounceAmountSlider.get_node("%SliderValue").value = settings_dict.bounceSlider
	%GravityAmountSlider.get_node("%SliderValue").value = settings_dict.bounceGravity
	%BGColorPicker.color = settings_dict.bg_color
	$TopBarInput.origin_alias()
	%BounceStateCheck.button_pressed = settings_dict.bounce_state
	%XFreqWobbleSlider.value = settings_dict.xFrq
	%XAmpWobbleSlider.value = settings_dict.xAmp
	%YFreqWobbleSlider.value = settings_dict.yFrq
	%YAmpWobbleSlider.value = settings_dict.yAmp

	if Global.camera != null && is_instance_valid(Global.camera):
		Global.camera.zoom = settings_dict.zoom
		Global.camera.get_parent().global_position = settings_dict.pan
	update_fps(settings_dict.max_fps)
	if Global.settings_dict.auto_save:
		Themes.save_timer.start()
		
func update_fps(value):
	if value == 241:
		Engine.max_fps = 0
		return
	
	Engine.max_fps = value
