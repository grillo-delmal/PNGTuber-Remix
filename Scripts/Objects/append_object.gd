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
	scale = Vector2(1.0,1.0),
	folder = false,
	position = Vector2.ZERO,
	rotation = 0.0,
	offset = Vector2.ZERO,
	ignore_bounce = false,
	clip = 0,
	physics = true,
	wiggle_segm = 5,
	wiggle_curve = 0,
	wiggle_stiff = 20,
	wiggle_max_angle = 0.5,
	wiggle_physics_stiffness = 2.5,
	wiggle_gravity = Vector2(0,0),
	wiggle_closed_loop = false,
	advanced_lipsync = false,
	look_at_mouse_pos = 0,
	look_at_mouse_pos_y = 0,
	should_rotate = false,
	should_rot_speed = 0.001,
	width = 80,
	segm_length = 30,
	subdivision = 5,
	should_reset = false,
	should_reset_state = false,
	one_shot = false,
	rainbow = false,
	rainbow_self = false,
	rainbow_speed = 0.01,
	follow_wa_tip = false,
	tip_point = 0,
	auto_wag = false,
	wag_mini = -180,
	wag_max = 180,
	wag_speed = 0.5,
	wag_freq = 0.02,
	follow_wa_mini = -180,
	follow_wa_max = 180,
	
	max_angular_momentum = 15,
	damping = 5,
	comeback_speed = 0.419,
	follow_mouse_velocity = false,
	flip_h = false,
	flip_v = false,
	rot_frq = 0.0,
	mouse_rotation = 0.0,
	mouse_scale_x = 0.0,
	mouse_scale_y = 0.0,
	mouse_rotation_max = 0.0,
	mouse_delay = 0.1,
	
	tile = 2,
	}

var smooth_rot = 0.0
var smooth_glob = Vector2(0.0,0.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.reparent_objects.connect(reparent_obj)
	%Dragger.top_level = true
	%Dragger.global_position = %Wobble.global_position
	set_process(true)
	update_wiggle_parts()
	Global.reinfo.connect(sel)
	Global.deselect.connect(desel)

func sel():
	if self in Global.held_sprites:
		selected = true
		%Origin.show()
	else:
		%Origin.hide()
		desel()

func desel():
	%Origin.hide()
	selected = false


func correct_sprite_size():
	var w = %Sprite2D.texture.get_image().get_size().y / 0.98
	var l = %Sprite2D.texture.get_image().get_size().x / 5
	
	sprite_data.width = w
	sprite_data.segm_length = l

func _process(_delta):
	if selected:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS
		%Selection.show()
	else:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		%Selection.hide()
	#	%Origin.mouse_filter = 2
	if dragging:
		var mpos = get_parent().to_local(get_global_mouse_position())
		position = mpos - of
		sprite_data.position = position
		save_state(Global.current_state)
		Global.update_pos_spins.emit()
	
	
	if !Global.static_view:
		if sprite_data.auto_wag:
			%Sprite2D.curvature = clamp(sin(Global.tick*(sprite_data.wag_freq))*sprite_data.wag_speed, deg_to_rad(sprite_data.wag_mini), deg_to_rad(sprite_data.wag_max))
	else:
		if sprite_data.auto_wag:
			%Sprite2D.curvature = 0.0
		
	%Grab.anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT

func wiggle_sprite():
	var wiggle_val = sin(Global.tick*sprite_data.wiggle_freq)*sprite_data.wiggle_amp
	if sprite_data.wiggle_physics:
		if get_parent() is Sprite2D or get_parent() is WigglyAppendage2D:
			var c_parent = get_parent().owner
			var c_parrent_length = (c_parent.glob.y - c_parent.dragger.global_position.y)
			wiggle_val = wiggle_val + (c_parrent_length/10)
		
		
	%Sprite2D.material.set_shader_parameter("rotation", wiggle_val )

func save_state(id):
	var dict : Dictionary = sprite_data.duplicate()
	states[id] = dict

func get_state(id):
	if not states[id].is_empty():
		var dict = states[id]
		sprite_data.merge(dict, true)
		%Wobble.z_index = sprite_data.z_index
		modulate = sprite_data.colored
		visible = sprite_data.visible
		scale = sprite_data.scale
	#	global_position = sprite_data.global_position
		if sprite_data.should_reset_state:
			%ReactionConfig.reset_anim()
	
	
		position = sprite_data.position
		%Sprite2D.position = sprite_data.offset 
		%Sprite2D.scale = Vector2(1,1)
		
		%Sprite2D.closed = sprite_data.wiggle_closed_loop
		%Sprite2D.gravity = sprite_data.wiggle_gravity
		
		if sprite_data.look_at_mouse_pos == 0:
			%Pos.position.x = 0
		if sprite_data.look_at_mouse_pos_y == 0:
			%Pos.position.y = 0
		
		%Sprite2D.texture_mode = sprite_data.tile
		
		%Sprite2D.set_clip_children_mode(sprite_data.clip)
		rotation = sprite_data.rotation

		if sprite_data.flip_h:
			%AppendageFlip.scale.x = -1
		else:
			%AppendageFlip.scale.x = 1
		if sprite_data.flip_v:
			%AppendageFlip.scale.y = -1
		else:
			%AppendageFlip.scale.y = 1
		
		if !sprite_data.should_blink:
			%Pos.show()
		else:
			%ReactionConfig.update_to_mode_change(Global.mode)
			
		update_wiggle_parts()
#		animation()
		set_blend(sprite_data.blend_mode)
		if sprite_data.one_shot:
			if is_apng:
				%AnimatedSpriteTexture.index = 0
				%AnimatedSpriteTexture.proper_apng_one_shot()
	elif states[id].is_empty():
		states[id] = sprite_data.duplicate(true)


func update_wiggle_parts():
	if %Sprite2D.segment_count != sprite_data.wiggle_segm:
		%Sprite2D.segment_count = sprite_data.wiggle_segm
	if %Sprite2D.curvature != sprite_data.wiggle_curve:
		%Sprite2D.curvature = sprite_data.wiggle_curve
	if %Sprite2D.stiffness != sprite_data.wiggle_stiff:
		%Sprite2D.stiffness = sprite_data.wiggle_stiff
	if %Sprite2D.max_angle != sprite_data.wiggle_max_angle:
		%Sprite2D.max_angle = sprite_data.wiggle_max_angle
	
	if %Sprite2D.width != sprite_data.width:
		%Sprite2D.width = sprite_data.width
	if %Sprite2D.segment_length != sprite_data.segm_length:
		%Sprite2D.segment_length = sprite_data.segm_length
	if %Sprite2D.subdivision!= sprite_data.subdivision:
		%Sprite2D.subdivision = sprite_data.subdivision
		
	if %Sprite2D.comeback_speed!= sprite_data.comeback_speed:
		%Sprite2D.comeback_speed = sprite_data.comeback_speed
		
	if %Sprite2D.max_angular_momentum!= sprite_data.max_angular_momentum:
		%Sprite2D.max_angular_momentum = sprite_data.max_angular_momentum
		
	if %Sprite2D.damping!= sprite_data.damping:
		%Sprite2D.damping = sprite_data.damping

func check_talk():
	if sprite_data.should_talk:
		if sprite_data.open_mouth:
			%Rotation.hide()
		else:
			%Rotation.show()

func _on_grab_button_down():
	if selected:
		of = get_parent().to_local(get_global_mouse_position()) - position
		dragging = true

func _on_grab_button_up():
	if selected:
		dragging = false
		save_state(Global.current_state)

func _input(event: InputEvent) -> void:
	if event.is_action_released("lmb"):
		if selected && dragging:
			save_state(Global.current_state)
			dragging = false
