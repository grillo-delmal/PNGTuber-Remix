extends SpriteObject


var sprite_data : Dictionary = {
	xFrq = 0,
	xAmp = 0,
	yFrq = 0,
	yAmp = 0,
	rdragStr = 0,
	rLimitMax = 180,
	rLimitMin = -180,
	dragSpeed = 0,
	stretchAmount = 0,
	blend_mode = "Normal",
	visible = true,
	colored = Color.WHITE,
	tint = Color.WHITE,
	z_index = 0,
	open_eyes = true,
	open_mouth = false,
	should_blink = false,
	should_talk =  false,
	animation_speed = 1,
	hframes = 1,
	vframes = 1,
	scale = Vector2(1,1),
	folder = false,
#	global_position = global_position,
	position = Vector2.ZERO,
	rotation = 0.0,
	offset = Vector2(0,0),
	ignore_bounce = false,
	clip = 0,
	physics = true,
	wiggle = false,
	wiggle_amp = 0,
	wiggle_freq = 0,
	wiggle_physics = false,
	wiggle_rot_offset = Vector2(0.5, 0.5),
	advanced_lipsync = false,
	look_at_mouse_pos = 0,
	look_at_mouse_pos_y = 0,
	should_rotate = false,
	should_rot_speed = 0.01,
	should_reset = false,
	should_reset_state = false,
	one_shot = false,
	rainbow = false,
	rainbow_self = false,
	rainbow_speed = 0.01,
	follow_parent_effects = false,
	follow_wa_tip = false,
	tip_point = 0,
	follow_wa_mini = -180,
	follow_wa_max = 180,
	flip_sprite_h = false,
	flip_sprite_v = false,
	follow_mouse_velocity = false,
	rot_frq = 0.0,
	mouse_rotation = 0.0,
	mouse_scale_x = 0.0,
	mouse_scale_y = 0.0,
	mouse_rotation_max = 0.0,
	mouse_delay = 0.1,
	non_animated_sheet = false,
	animate_to_mouse = false,
	animate_to_mouse_speed = 10,
	animate_to_mouse_track_pos = true,
	frame = 0,
	static_obj = false,
	is_cycle = false,
	cycle = 0,
	}

var wiggle_val : float = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	Global.reparent_objects.connect(reparent_obj)
	og_glob = sprite_data.position
	animation()
	%Dragger.top_level = true
	%Dragger.global_position = %Wobble.global_position
	Global.reinfo.connect(sel)
	Global.deselect.connect(desel)

func sel():
	if self in Global.held_sprites:
		selected = true
		%Origin.show()
		%Grab.anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		%Grab.modulate.a = 1.0
	else:
		%Origin.hide()

		desel()

func desel():
	%Origin.hide()
	selected = false

func animation():
	if not sprite_data.non_animated_sheet:
		if not sprite_data.advanced_lipsync:
			%Sprite2D.hframes = sprite_data.hframes
			%Sprite2D.vframes = sprite_data.vframes
			if sprite_data.hframes > 1 or sprite_data.vframes > 1:
				if sprite_data.one_shot &&  %Sprite2D.frame == (sprite_data.hframes*sprite_data.vframes) - 1:
					return
				%Sprite2D.frame = wrapi(%Sprite2D.frame + 1, 0, (sprite_data.hframes*sprite_data.vframes))
			else:
				%Sprite2D.frame = 0

	elif sprite_data.non_animated_sheet:
		%Sprite2D.hframes = sprite_data.hframes
		%Sprite2D.vframes = sprite_data.vframes
		if (sprite_data.hframes*sprite_data.vframes) - 1 > 1:
			if !sprite_data.animate_to_mouse:
				%Sprite2D.frame = sprite_data.frame
	
	$Animation.wait_time = 1.0/sprite_data.animation_speed 
	$Animation.start()

func _process(_delta):
	if selected:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS
		%Selection.texture = %Sprite2D.texture
		%Selection.show()
		%Selection.hframes = %Sprite2D.hframes
		%Selection.vframes = %Sprite2D.vframes
		%Selection.frame = %Sprite2D.frame
		%Selection.flip_h = %Sprite2D.flip_h
		%Selection.flip_v = %Sprite2D.flip_v
		
		if sprite_data.wiggle:
			%WiggleOrigin.show()
			var pos = (%Sprite2D.material.get_shader_parameter("rotation_offset") * %Sprite2D.texture.get_size())/2
			%WiggleOrigin.position = Vector2(pos.x, pos.y)
			%Selection.material.set_shader_parameter("wiggle", true)
			%Selection.material.set_shader_parameter("rotation_offset", %Sprite2D.material.get_shader_parameter("rotation_offset"))
			%Selection.material.set_shader_parameter("rotation", %Sprite2D.material.get_shader_parameter("rotation"))
		else:
			%Selection.material.set_shader_parameter("wiggle", false)
			%WiggleOrigin.hide()
		
	else:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		%Selection.hide()
		%Grab.modulate.a = 0.0
		%WiggleOrigin.hide()
	
	if dragging:
		var mpos = get_parent().to_local(get_global_mouse_position())
		position = mpos - of
		sprite_data.position = position
		save_state(Global.current_state)
		Global.update_pos_spins.emit()
		
	if !Global.static_view:
		if sprite_data.wiggle:
			wiggle_sprite()
	else:
		if sprite_data.wiggle:
			%Sprite2D.material.set_shader_parameter("rotation", 0)
		
	advanced_lipsyc()

func wiggle_sprite():
	var length : float = 0
	if sprite_data.wiggle_physics:
		if (get_parent() is Sprite2D  or get_parent() is WigglyAppendage2D) && is_instance_valid(get_parent()):
			var c_parent = get_parent().owner
			if c_parent != null && is_instance_valid(c_parent):
				var c_parrent_length = (c_parent.get_node("Movements").glob.y - c_parent.get_node("%Drag").global_position.y)
				var c_parrent_length2 = (c_parent.get_node("%Movements").glob.x - c_parent.get_node("%Drag").global_position.x)
				length +=((c_parrent_length + c_parrent_length2)/20)
	
	
	wiggle_val = lerp(wiggle_val, sin((Global.tick*sprite_data.wiggle_freq)+length)*sprite_data.wiggle_amp, 0.05)
	
	if !get_parent() is Sprite2D:
		%Sprite2D.material.set_shader_parameter("rotation", wiggle_val )
	elif get_parent() is Sprite2D:
		if sprite_data.follow_parent_effects:
			var c_parent = get_parent().owner
			%Sprite2D.material.set_shader_parameter("rotation", c_parent.get_node("%Sprite2D").material.get_shader_parameter("rotation"))
		else:
			%Sprite2D.material.set_shader_parameter("rotation", wiggle_val )

func advanced_lipsyc():
	if sprite_data.advanced_lipsync:
		if %Sprite2D.hframes != 14:
			%Sprite2D.hframes = 14
		if %ReactionConfig.currently_speaking:
			if GlobalAudioStreamPlayer.t.value == 0:
				%Sprite2D.frame_coords.x = 13
			else:
				%Sprite2D.frame_coords.x = GlobalAudioStreamPlayer.t.actual_value
		else:
			%Sprite2D.frame_coords.x = 13

func save_state(id):
	var dict : Dictionary = sprite_data.duplicate()
	states[id] = dict

func get_state(id):
	if !states[id].is_empty():
		var dict = states[id]
		sprite_data.merge(dict, true)
		
		
		if sprite_data.should_reset_state:
			%ReactionConfig.reset_anim()
		
		%Sprite2D.position = sprite_data.offset 
		%Sprite2D.scale = Vector2(1,1)
		
		%Wobble.z_index = sprite_data.z_index
		modulate = sprite_data.colored
		scale = sprite_data.scale
	#	global_position = sprite_data.global_position
		position = sprite_data.position

		%Sprite2D.set_clip_children_mode(sprite_data.clip)
		rotation = sprite_data.rotation
		%Sprite2D.material.set_shader_parameter("wiggle", sprite_data.wiggle)
		%Sprite2D.material.set_shader_parameter("rotation_offset", sprite_data.wiggle_rot_offset)
		
		if sprite_data.flip_sprite_h:
			%Sprite2D.scale.x = -1
		else:
			%Sprite2D.scale.x = 1
		
		if sprite_data.flip_sprite_v:
			%Sprite2D.scale.y = -1
		else:
			%Sprite2D.scale.y = 1

		if sprite_data.advanced_lipsync:
			%Sprite2D.hframes = 6
		
		if !sprite_data.should_blink:
			%Pos.show()
		else:
			%ReactionConfig.update_to_mode_change(Global.mode)

		visible = sprite_data.visible
		
		animation()
		set_blend(sprite_data.blend_mode)
		advanced_lipsyc()

		if sprite_data.look_at_mouse_pos == 0:
			%Pos.position.x = 0
		if sprite_data.look_at_mouse_pos_y == 0:
			%Pos.position.y = 0
			
		if !sprite_data.cycle in range(Global.settings_dict.cycles.size()):
			sprite_data.cycle = 0
		
	elif states[id].is_empty():
		states[id] = sprite_data.duplicate(true)
		


func check_talk():
	if sprite_data.should_talk:
		if sprite_data.open_mouth:
			%Rotation.hide()
		else:
			%Rotation.show()
	else:
		%Rotation.show()

func _on_grab_button_down():
	if selected:
		if not Input.is_action_pressed("ctrl"):
			of = get_parent().to_local(get_global_mouse_position()) - position
			dragging = true

func _on_grab_button_up():
	if selected && dragging:
		save_state(Global.current_state)
		dragging = false

func _input(event: InputEvent) -> void:
	if event.is_action_released("lmb"):
		if selected && dragging:
			save_state(Global.current_state)
			dragging = false

func zazaza(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			sprite_data.position -= i.sprite_data.offset
			if is_plus_first_import:
				for state in states:
					if !state.is_empty():
						global = global_position
						state.position = sprite_data.position
