extends Node

@export var actor : Node
@export var animation_handler : Node
var currently_speaking : bool = false
var blinking : bool = false


func _ready() -> void:
	Global.speaking.connect(speaking)
	Global.not_speaking.connect(not_speaking)
	Global.blink.connect(blink)
	Global.mode_changed.connect(update_to_mode_change)
	Global.blink.connect(editor_blink)
	Global.animation_state.connect(reset_animations)
	await  get_tree().physics_frame
	not_speaking()

func _physics_process(_delta: float) -> void:
	if Global.settings_dict.checkinput != true:
		return
		
	# pressed hotkeys, pressed(and holding) key with hold_to_show feature
	# BUG: is_action_just_pressed() ignores some key inputs when quickly and repeatedly pressed,
	#      but is_action_pressed() can capture key inputs every frame.
	var is_trying_to_appear = false
	var is_trying_to_disappear = false
	if GlobInput.is_action_just_pressed(str(actor.sprite_id)):
		if actor.show_only:
			%Sprite2D.visible = true
		else:
			%Sprite2D.visible = !%Sprite2D.visible
		actor.was_active_before = %Sprite2D.visible
	
	# case to toggle:
	if GlobInput.is_action_just_pressed(str(actor.sprite_id)):
		if %Drag.visible and !actor.show_only:
			is_trying_to_disappear = true
		elif !%Drag.visible:
			is_trying_to_appear = true
	#case to hold_to_show 
	if GlobInput.is_action_pressed(str(actor.sprite_id)) and actor.hold_to_show and !actor.was_active_before:
		is_trying_to_appear = true
	# case to disappear:
	# pressed disappear_keys, released key with hold_to_show feature 
	if GlobInput.is_action_just_pressed(actor.disappear_keys):
		is_trying_to_disappear = true
	if !GlobInput.is_action_pressed(str(actor.sprite_id)) and actor.hold_to_show and actor.was_active_before:
		is_trying_to_disappear = true
	
	if is_trying_to_appear:
		%Drag.visible = true
	if is_trying_to_disappear:
		%Drag.visible = false
		if !actor.is_asset && !%Drag.visible:
			%Drag.visible = true
	
	actor.was_active_before = %Drag.visible
	
	# trying to show sprite in a cycle will hide the remained
	# hiding will display the first sprite
	# TODO: move to cycle.gd
	# TODO: consider whether the effectw of hiding sprite meets user expectations
	if actor.sprite_data.is_cycle and actor.sprite_data.cycle > 0:
		var cycle = Global.settings_dict.cycles[actor.sprite_data.cycle - 1]
		var sprite_pos = cycle.sprites.find(actor.sprite_id)
		
		if is_trying_to_appear:
			cycle.active = true
			cycle.pos = sprite_pos
			cycle.last_sprite = actor.sprite_id
			
			for sprite in get_tree().get_nodes_in_group("Sprites"):
				if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
					sprite.get_node("%Drag").hide()
					sprite.was_active_before = sprite.get_node("%Drag").visible
				if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
					sprite.get_node("%Drag").show()
					sprite.was_active_before = sprite.get_node("%Drag").visible
					
		if is_trying_to_disappear:
			cycle.active = true
			cycle.pos = 0
			cycle.last_sprite = cycle.sprites[0]
			
			for sprite in get_tree().get_nodes_in_group("Sprites"):
				if sprite.sprite_id in cycle.sprites and sprite.get_value("is_cycle"):
					sprite.get_node("%Drag").hide()
					sprite.was_active_before = sprite.get_node("%Drag").visible
				if sprite.sprite_id == cycle.last_sprite and sprite.get_value("is_cycle"):
					sprite.get_node("%Drag").show()
					sprite.was_active_before = sprite.get_node("%Drag").visible
		%Sprite2D.visible = false
		actor.was_active_before = false
		if !actor.is_asset && !%Sprite2D.visible:
			%Sprite2D.visible = true
			actor.was_active_before = true

func update_to_mode_change(mode : int):
	match mode:
		0:
			%Modifier1.show()
			if actor.get_value("should_blink"):
				if actor.get_value("open_eyes"):
					if !blinking:
						%Modifier1.modulate.a = 1
					elif blinking:
						%Modifier1.modulate.a = 0.2

				elif !actor.get_value("open_eyes"):
					if blinking:
						%Modifier1.modulate.a = 1
					elif !blinking:
						%Modifier1.modulate.a = 0.2

			
			%Modifier.show()
			if actor.get_value("should_talk"):
				if actor.get_value("open_mouth"):
					if currently_speaking:
						%Modifier.modulate.a = 1
					else:
						%Modifier.modulate.a = 0.2

				elif !actor.get_value("open_mouth"):
					if !currently_speaking:
						%Modifier.modulate.a = 1
					else:
						%Modifier.modulate.a = 0.2
			else:
				%Modifier.show()
				%Modifier.modulate.a = 1
		1:
			%Modifier1.modulate.a = 1
			if actor.get_value("should_blink"):
				if actor.get_value("open_eyes"):
					if !blinking:
						%Modifier1.show()
					elif blinking:
						%Modifier1.hide()

				elif !actor.get_value("open_eyes"):
					if blinking:
						%Modifier1.show()
					elif !blinking:
						%Modifier1.hide()

			%Modifier.modulate.a = 1
			if actor.get_value("should_talk"):
				if actor.get_value("open_mouth"):
					if currently_speaking:
						%Modifier.show()
					else:
						%Modifier.hide()

				elif !actor.get_value("open_mouth"):
					if !currently_speaking:
						%Modifier.show()
					else:
						%Modifier.hide()
			else:
				%Modifier.show()
				%Modifier.modulate.a = 1

func editor_blink():
	if Global.mode == 0:
		if actor.get_value("should_blink"):
			%Modifier1.show()
			if not actor.get_value("open_eyes"):
				%Modifier1.modulate.a = 1
				reset_animations()
			else:
				%Modifier1.modulate.a = 0.2
		
		blinking = true
		%Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
		%Blink.start()
		await %Blink.timeout
		if actor.get_value("should_blink"):
			if not actor.get_value("open_eyes"):
				%Modifier1.modulate.a = 0.2
			else:
				%Modifier1.modulate.a = 1
				reset_animations()
		else:
			%Modifier1.modulate.a = 1
		blinking = false

func blink():
	if Global.mode != 0:
		if actor.get_value("should_blink"):
			%Modifier1.modulate.a = 1
			if not actor.get_value("open_eyes"):
				%Modifier1.show()
				reset_animations()
			else:
				%Modifier1.hide()
		
		blinking = true
		%Blink.wait_time = 0.2 * Global.settings_dict.blink_speed
		%Blink.start()
		await %Blink.timeout
		if actor.get_value("should_blink"):
			if not actor.get_value("open_eyes"):
				%Modifier1.hide()
			else:
				%Modifier1.show()
				reset_animations()
		else:
			%Modifier1.show()
		blinking = false

func speaking():
	if Global.mode != 0:
		%Modifier.modulate.a = 1
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				reset_animations()
				%Modifier.show()
					
			else:
				%Modifier.hide()
		else:
			%Modifier.show()
			
	elif Global.mode == 0:
		%Modifier.show()
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Modifier.modulate.a = 1
				reset_animations()
			else:
				%Modifier.modulate.a = 0.2
		else:
			%Modifier.modulate.a = 1
	currently_speaking = true

func reset_animations(_place_holder : int = 0):
	if actor.get_value("one_shot"):
		reset_anim()
	
	if actor.get_value("should_reset"):
		reset_anim()

func reset_anim():
	if actor.referenced_data.is_apng or actor.referenced_data.img_animated:
		animation_handler.index = 0
		animation_handler.proper_apng_one_shot()
	animation_handler.played_once = false
	if actor.sprite_type == "Sprite2D":
		%Sprite2D.frame = 0
		actor.animation()

func not_speaking():
	if Global.mode != 0:
		%Modifier.modulate.a = 1
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Modifier.hide()
			else:
				reset_animations()
				%Modifier.show()
		else:
			%Modifier.show()
			
	elif Global.mode == 0:
		%Modifier.show()
		if actor.get_value("should_talk"):
			if actor.get_value("open_mouth"):
				%Modifier.modulate.a = 0.2
			else:
				reset_animations()
				%Modifier.modulate.a = 1
		else:
			%Modifier.modulate.a = 1
			
	currently_speaking = false
