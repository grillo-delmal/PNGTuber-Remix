extends Node

@export var actor : Node
@export var animation_handler : Node

func _ready() -> void:
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	Global.blink.connect(blink)
	get_tree().get_root().get_node("Main").key_pressed.connect(asset)
	get_tree().get_root().get_node("Main").key_pressed.connect(should_disappear)
	Global.mode_changed.connect(update_to_mode_change)
	Global.blink.connect(editor_blink)

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
			editor_blink()
			%Rotation.show()
			if actor.dictmain.should_talk:
				if actor.currently_speaking:
					if actor.dictmain.open_mouth:
						%Rotation.modulate.a = 1
					else:
						%Rotation.modulate.a = 0.2
				if !actor.currently_speaking:
					if !actor.dictmain.open_mouth:
						%Rotation.modulate.a = 0.2
					else:
						%Rotation.modulate.a = 1
			else:
				%Rotation.show()
				%Rotation.modulate.a = 1
		1:
			blink()
			%Rotation.modulate.a = 1
			if actor.dictmain.should_talk:
				if actor.currently_speaking:
					if actor.dictmain.open_mouth:
						%Rotation.show()
					else:
						%Rotation.hide()
				elif !actor.currently_speaking:
					if !actor.dictmain.open_mouth:
						%Rotation.show()
					else:
						%Rotation.hide()
			else:
				%Rotation.show()
				%Rotation.modulate.a = 1

func editor_blink():
	if Global.mode == 0:
		if actor.dictmain.should_blink:
			%Pos.show()
			if not actor.dictmain.open_eyes:
				%Pos.modulate.a = 1
				reset_animations()
			else:
				%Pos.modulate.a = 0.2
		
		%Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
		%Blink.start()
		await  %Blink.timeout
		if actor.dictmain.should_blink:
			if not actor.dictmain.open_eyes:
				%Pos.modulate.a = 0.2
			else:
				%Pos.modulate.a = 1
				reset_animations()
		else:
			%Pos.modulate.a = 1

func blink():
	if Global.mode != 0:
		if actor.dictmain.should_blink:
			%Pos.modulate.a = 1
			if not actor.dictmain.open_eyes:
				%Pos.show()
				reset_animations()
			else:
				%Pos.hide()
		
		%Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
		%Blink.start()
		await  %Blink.timeout
		if actor.dictmain.should_blink:
			if not actor.dictmain.open_eyes:
				%Pos.hide()
			else:
				%Pos.show()
				reset_animations()
		else:
			%Pos.show()

func speaking():
	if Global.mode != 0:
		%Rotation.modulate.a = 1
		if actor.dictmain.should_talk:
			if actor.dictmain.open_mouth:
				reset_animations()
				%Rotation.show()
					
			else:
				%Rotation.hide()
		else:
			%Rotation.show()
			
	elif Global.mode == 0:
		%Rotation.show()
		if actor.dictmain.should_talk:
			if actor.dictmain.open_mouth:
				if actor.dictmain.one_shot:
					%Rotation.modulate.a = 1
					reset_animations()
			else:
				%Rotation.modulate.a = 0.2
		else:
			%Rotation.modulate.a = 1
	actor.currently_speaking = true

func reset_animations():
	if actor.is_apng:
		animation_handler.index = 0
		animation_handler.proper_apng_one_shot()
	animation_handler.played_once = false
	if actor.sprite_type == "Sprite2D":
		%Sprite2D.frame = 0
		actor.animation()

func not_speaking():
	if Global.mode != 0:
		%Rotation.modulate.a = 1
		if actor.dictmain.should_talk:
			if actor.dictmain.open_mouth:
				%Rotation.hide()
			else:
				reset_animations()
				%Rotation.show()
		else:
			%Rotation.show()
			
	elif Global.mode == 0:
		%Rotation.show()
		if actor.dictmain.should_talk:
			if actor.dictmain.open_mouth:
				
				%Rotation.modulate.a = 0.2
			else:
				reset_animations()
				%Rotation.modulate.a = 1
		else:
			%Rotation.modulate.a = 1
			
	actor.currently_speaking = false
