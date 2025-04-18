extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().current_scene.ready
	%ScrollContainer.get_tab_bar().focus_mode = Control.FocusMode.FOCUS_NONE
	held_sprite_is_null()
	Global.connect("reinfo", reinfo)
	Global.deselect.connect(held_sprite_is_null)

#region Update Slider info
func held_sprite_is_null():
	%Name.editable = false
	%Name.text = ""
	%NonAnimatedSheetCheck.disabled = true
	%FrameSpinbox.editable = false
	%AdvancedLipSync.disabled = true

func held_sprite_is_true():
	Global.top_ui.get_node("%DeselectButton").show()
	%Name.editable = true
	%AdvancedLipSync.disabled = false
	if Global.held_sprite.sprite_type == "Sprite2D":
		%NonAnimatedSheetCheck.disabled = false
		%FrameSpinbox.editable = true

func reinfo():
	held_sprite_is_null()
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		await get_tree().create_timer(0.01).timeout
		held_sprite_is_true()
		%Name.text = Global.held_sprite.sprite_name
		%AdvancedLipSync.button_pressed = Global.held_sprite.sprite_data.advanced_lipsync
		if Global.held_sprite.sprite_type == "Sprite2D":
			%NonAnimatedSheetCheck.button_pressed = Global.held_sprite.sprite_data.non_animated_sheet
			%FrameSpinbox.value = Global.held_sprite.sprite_data.frame

func _on_name_text_submitted(new_text):
	Global.held_sprite.treeitem.set_text(0, new_text)
	Global.held_sprite.sprite_name = new_text
	Global.held_sprite.save_state(Global.current_state)
	Global.spinbox_held = false
	%Name.release_focus()
#endregion

#region Advanced-LipSync
func _on_advanced_lip_sync_toggled(toggled_on):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.advanced_lipsync = toggled_on
		if Global.held_sprite.sprite_type == "Sprite2D":
			Global.held_sprite.sprite_data.animation_speed = 1
			if toggled_on:
				Global.held_sprite.get_node("%Sprite2D").hframes = 6
			else:
				Global.held_sprite.get_node("%Sprite2D").hframes = 1
			Global.held_sprite.advanced_lipsyc()
			Global.held_sprite.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
			Global.held_sprite.save_state(Global.current_state)
			Global.reinfo.emit()

func _on_advanced_lip_sync_mouse_entered():
	%AdvancedLipSyncLabel.show()

func _on_advanced_lip_sync_mouse_exited():
	%AdvancedLipSyncLabel.hide()
#endregion

func _on_mini_rotation_level_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.rLimitMin = value
		Global.held_sprite.save_state(Global.current_state)

func _on_max_rotation_level_value_changed(value):
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		Global.held_sprite.sprite_data.rLimitMax = value
		Global.held_sprite.save_state(Global.current_state)

func _on_name_focus_entered() -> void:
	Global.spinbox_held = true

func _on_name_focus_exited() -> void:
	Global.spinbox_held = false

func _on_non_animated_sheet_check_toggled(toggled_on: bool) -> void:
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if Global.held_sprite.sprite_type == "Sprite2D":
			%FrameSpinbox.max_value = Global.held_sprite.get_node("%Sprite2D").hframes - 1
			Global.held_sprite.sprite_data.non_animated_sheet = toggled_on
			Global.held_sprite.animation()
		if toggled_on:
			%FrameHBox.show()
		else:
			%FrameHBox.hide()

func _on_frame_spinbox_value_changed(value: float) -> void:
	if Global.held_sprite != null && is_instance_valid(Global.held_sprite):
		if Global.held_sprite.sprite_type == "Sprite2D":
			%FrameSpinbox.max_value = Global.held_sprite.get_node("%Sprite2D").hframes - 1
			Global.held_sprite.sprite_data.frame = clamp(value, 0, Global.held_sprite.get_node("%Sprite2D").hframes - 1)
			Global.held_sprite.get_node("%Sprite2D").frame = clamp(value, 0, Global.held_sprite.get_node("%Sprite2D").hframes - 1)
