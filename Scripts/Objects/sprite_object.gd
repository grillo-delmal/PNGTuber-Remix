extends SpriteObject

#Movement
var heldTicks = 0
#Wobble
var squish = 1

# Misc
var treeitem = null
var visb

var sprite_name : String = ""
@export var states : Array = [{}]
var coord
var dragging : bool = false
var of = Vector2(0,0)

var sprite_id : float
var parent_id 
var physics_effect = 1
var glob
var sprite_type : String = "Sprite2D"
var currently_speaking : bool = false
var is_plus_first_import : bool = false
var image_data : PackedByteArray = []
var normal_data : PackedByteArray = []

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
	mouse_rotation_min = 0.0,
	non_animated_sheet = false,
	frame = 0,
	}

var anim_texture 
var anim_texture_normal 
var img_animated : bool = false
var is_apng : bool = false
var is_collapsed : bool = false
var played_once : bool = false


@onready var og_glob = global_position

var dt = 0.0
var frames : Array[AImgIOFrame] = []
var frames2 : Array[AImgIOFrame] = []
var fidx = 0

var saved_event : InputEvent
var is_asset : bool = false
var was_active_before : bool = true
var show_only : bool = false
var should_disappear : bool = false
var saved_keys : Array = []

var last_mouse_position : Vector2 = Vector2(0,0)
var last_dist : Vector2 = Vector2(0,0)
var global

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.reparent_objects.connect(reparent_obj)
	og_glob = sprite_data.position
	animation()
	%Dragger.top_level = true
	%Dragger.global_position = %Wobble.global_position

func animation():
	if not sprite_data.non_animated_sheet:
		if not sprite_data.advanced_lipsync:
			%Sprite2D.hframes = sprite_data.hframes
			%Sprite2D.vframes = 1
			if sprite_data.hframes > 1:
				coord = sprite_data.hframes -1
				if not coord <= 0:
					if %Sprite2D.frame == coord:
						if sprite_data.one_shot:
							return
						%Sprite2D.frame = 0
						
					elif sprite_data.hframes > 1:
						%Sprite2D.set_frame_coords(Vector2(clamp(%Sprite2D.frame +1, 0,coord), 0))
						
			else:
				%Sprite2D.set_frame_coords(Vector2(0, 0))
		
	elif sprite_data.non_animated_sheet:
		%Sprite2D.hframes = sprite_data.hframes
		%Sprite2D.vframes = 1
		if sprite_data.hframes > 1:
			%Sprite2D.frame = sprite_data.frame
	
	$Animation.wait_time = 1.0/sprite_data.animation_speed 
	$Animation.start()

func _process(_delta):
	if Global.held_sprite == self:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS
		%Selection.texture = %Sprite2D.texture
		%Selection.show()
		%Selection.hframes = %Sprite2D.hframes
		%Selection.frame = %Sprite2D.frame
		%Selection.flip_h = %Sprite2D.flip_h
		
		if sprite_data.wiggle:
			%WiggleOrigin.show()
			var pos = (%Sprite2D.material.get_shader_parameter("rotation_offset") * %Sprite2D.texture.get_size())/2
			%WiggleOrigin.position = Vector2(pos.x, pos.y)
			%Selection.material.set_shader_parameter("wiggle", true)
			%Selection.material.set_shader_parameter("rotation_offset", %Sprite2D.material.get_shader_parameter("rotation_offset"))
		else:
			%Selection.material.set_shader_parameter("wiggle", false)
			%WiggleOrigin.hide()
		
	else:
		%Grab.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		%Selection.hide()
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
	var wiggle_val = sin(Global.tick*sprite_data.wiggle_freq)*sprite_data.wiggle_amp
	if sprite_data.wiggle_physics:
		if get_parent() is Sprite2D or get_parent() is WigglyAppendage2D && is_instance_valid(get_parent()):
			var c_parent = get_parent().owner
			if c_parent != null && is_instance_valid(c_parent):
				var c_parrent_length = (c_parent.get_node("Movements").glob.y - c_parent.get_node("%Drag").global_position.y)
				wiggle_val = wiggle_val + (c_parrent_length/10)
			
	
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
		if currently_speaking:
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
	if not states[id].is_empty():
		var dict = states[id]
		sprite_data.merge(dict, true)
		
		if sprite_data.should_reset:
			if sprite_data.hframes > 1:
				%Sprite2D.frame = 0
				print(%Sprite2D.frame)
			elif is_apng:
				fidx = 0
		
		if sprite_data.one_shot:
			if is_apng:
				%AnimatedSpriteTexture.index = 0
				%AnimatedSpriteTexture.proper_apng_one_shot()
			elif sprite_data.hframes > 1:
				%Sprite2D.frame = 0
				print(%Sprite2D.frame)
		played_once = false
		
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
		
		
		%Sprite2D.flip_h = sprite_data.flip_sprite_h
		%Sprite2D.flip_v = sprite_data.flip_sprite_v

		if sprite_data.advanced_lipsync:
			%Sprite2D.hframes = 6
		
		if sprite_data.should_blink:
			if sprite_data.open_eyes:
				%Pos.show()
			else:
				%Pos.hide()
		else:
			%Pos.show()

		visible = sprite_data.visible
		%ReactionConfig.speaking()
		%ReactionConfig.not_speaking()
		
		animation()
		set_blend(sprite_data.blend_mode)
		advanced_lipsyc()

		%Squish.scale = Vector2(1,1)
		if sprite_data.look_at_mouse_pos == 0:
			%Pos.position.x = 0
		if sprite_data.look_at_mouse_pos_y == 0:
			%Pos.position.y = 0


func check_talk():
	if sprite_data.should_talk:
		if sprite_data.open_mouth:
			%Rotation.hide()
		else:
			%Rotation.show()
	else:
		%Rotation.show()

func set_blend(blend):
	match  blend:
		"Normal":
			%Sprite2D.material.set_shader_parameter("enabled", false)
		"Add":
			%Sprite2D.material.set_shader_parameter("enabled", true)
			%Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/add.png"))
		"Subtract":
			%Sprite2D.material.set_shader_parameter("enabled", true)
			%Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/exclusion.png"))
		"Multiply":
			%Sprite2D.material.set_shader_parameter("enabled", true)
			%Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/multiply.png"))
		"Burn":
			%Sprite2D.material.set_shader_parameter("enabled", true)
			%Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/burn.png"))
		"HardMix":
			%Sprite2D.material.set_shader_parameter("enabled", true)
			%Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/hardmix.png"))
		"Cursed":
			%Sprite2D.material.set_shader_parameter("enabled", true)
			%Sprite2D.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/test1.png"))

func _on_grab_button_down():
	if Global.held_sprite == self:
		if not Input.is_action_pressed("ctrl"):
			of = get_parent().to_local(get_global_mouse_position()) - position
			dragging = true

func _on_grab_button_up():
	if Global.held_sprite == self && dragging:
		save_state(Global.current_state)
		dragging = false

func _input(event: InputEvent) -> void:
	if event.is_action_released("lmb"):
		if Global.held_sprite == self && dragging:
			save_state(Global.current_state)
			dragging = false

func reparent_obj(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			#global = global_position
			reparent(i.get_node("%Sprite2D"))

func zazaza(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			sprite_data.position -= i.sprite_data.offset
			if is_plus_first_import:
				for state in states:
					if !state.is_empty():
						global = global_position
						state.position = sprite_data.position
