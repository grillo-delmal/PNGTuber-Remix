extends Node

@export var actor : Node
@export var animation_handler : Node
var currently_speaking : bool = false
var blinking : bool = false


func _ready() -> void:
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	Global.blink.connect(blink)
	Global.key_pressed.connect(asset)
	Global.key_pressed.connect(should_disappear)
	Global.mode_changed.connect(update_to_mode_change)
	Global.blink.connect(editor_blink)
	Global.animation_state.connect(reset_animations)
	await  get_tree().physics_frame
	not_speaking()
	

func asset(key):
	if actor.is_asset && InputMap.action_get_events(str(actor.sprite_id)).size() > 0:
		if actor.saved_event.as_text() == key:
			if actor.show_only:
				%Drag.visible = true
			else:
				%Drag.visible = !%Drag.visible
			actor.was_active_before = %Drag.visible

func should_disappear(key):
	if actor.should_disappear:
		if key in actor.saved_keys:
			%Drag.visible = false
			actor.was_active_before = false
			if !actor.is_asset && !%Drag.visible:
				%Drag.visible = true
				actor.was_active_before = true

func update_to_mode_change(mode : int):
	match mode:
		0:
			%Pos.show()
			if actor.get_value("should_blink"):
				if actor.get_value("open_eyes"):
					if !blinking:
						%Pos.modulate.a = 1
					elif blinking:
						%Pos.modulate.a = 0.2

				elif !actor.get_value("open_eyes"):
					if blinking:
						%Pos.modulate.a = 1
					elif !blinking:
						%Pos.modulate.a = 0.2

			
			%Rotation.show()
			if actor.get_value("should_talk"):
				if actor.get_value("open_mouth"):
					if currently_speaking:
						%Rotation.modulate.a = 1
					else:
						%Rotation.modulate.a = 0.2

				elif !actor.get_value("open_mouth"):
					if !currently_speaking:
						%Rotation.modulate.a = 1
					else:
						%Rotation.modulate.a = 0.2
			else:
				%Rotation.show()
				%Rotation.modulate.a = 1
		1:
			%Pos.modulate.a = 1
			if actor.get_value("should_blink"):
				if actor.get_value("open_eyes"):
					if !blinking:
						%Pos.show()
					elif blinking:
						%Pos.hide()

				elif !actor.get_value("open_eyes"):
					if blinking:
						%Pos.show()
					elif !blinking:
						%Pos.hide()

			%Rotation.modulate.a = 1
			if actor.get_value("should_talk"):
				if actor.get_value("open_mouth"):
					if currently_speaking:
						%Rotation.show()
					else:
						%Rotation.hide()

				elif !actor.get_value("open_mouth"):
					if !currently_speaking:
						%Rotation.show()
					else:
						%Rotation.hide()
			else:
				%Rotation.show()
				%Rotation.modulate.a = 1

func editor_blink():
	if Global.mode == 0:
		if actor.get_value("should_blink"):
			%Pos.show()
			if not actor.get_value("open_eyes"):
				%Pos.modulate.a = 1
				reset_animations()
			else:
				%Pos.modulate.a = 0.2
		
		%Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
		%Blink.start()
		blinking = true
		await  %Blink.timeout
		if actor.get_value("should_blink"):
			if not actor.get_value("open_eyes"):
				%Pos.modulate.a = 0.2
			else:
				%Pos.modulate.a = 1
				reset_animations()
		else:
			%Pos.modulate.a = 1
		blinking = false

func blink():
	if Global.mode != 0:
		if actor.get_value("should_blink"):
			%Pos.modulate.a = 1
			if not actor.get_value("open_eyes"):
				%Pos.show()
				reset_animations()
			else:
				%Pos.hide()
		
		%Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
		%Blink.start()
		blinking = true
		await  %Blink.timeout
		if actor.get_value("should_blink"):
			if not actor.get_value("open_eyes"):
				%Pos.hide()
			else:
				%Pos.show()
				reset_animations()
		else:
			%Pos.show()
		blinking = false

func speaking():
	if Global.mode != 0:
		%Rotation.modulate.a = 1
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				reset_animations()
				%Rotation.show()
					
			else:
				%Rotation.hide()
		else:
			%Rotation.show()
			
	elif Global.mode == 0:
		%Rotation.show()
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Rotation.modulate.a = 1
				reset_animations()
			else:
				%Rotation.modulate.a = 0.2
		else:
			%Rotation.modulate.a = 1
	currently_speaking = true

func reset_animations(_place_holder : int = 0):
	if actor.get_value("one_shot"):
		reset_anim()
	
	if actor.get_value("should_reset"):
		reset_anim()

func reset_anim():
	if actor.is_apng or actor.img_animated:
		animation_handler.index = 0
		animation_handler.proper_apng_one_shot()
	animation_handler.played_once = false
	if actor.sprite_type == "Sprite2D":
		%Sprite2D.frame = 0
		actor.animation()

func not_speaking():
	if Global.mode != 0:
		%Rotation.modulate.a = 1
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Rotation.hide()
			else:
				reset_animations()
				%Rotation.show()
		else:
			%Rotation.show()
			
	elif Global.mode == 0:
		%Rotation.show()
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Rotation.modulate.a = 0.2
			else:
				reset_animations()
				%Rotation.modulate.a = 1
		else:
			%Rotation.modulate.a = 1
			
	currently_speaking = false
