extends Node

@export var actor : SpriteObject
var glob : Vector2 = Vector2.ZERO
var vel = Vector2.ZERO
var distance : Vector2 = Vector2.ZERO
var applied_pos = Vector2(0.0,0.0)
var applied_rotation = 0.0
var applied_scale = Vector2(1.0, 1.0)
var placeholder_position : Vector2 = Vector2.ZERO
var controller_vel : Vector2 = Vector2.ZERO
var target_rotation_axis : Vector2 = Vector2.ZERO
var target_scale_axis : Vector2 = Vector2.ZERO
var dir_vel_anim : Vector2 = Vector2.ZERO
var dist_vel_anim : float = 0.0
var vector_l_r : Vector2 = Vector2.ZERO
var vector_u_d : Vector2 = Vector2.ZERO
var clamped_angle : float = 0.0
var target_angle : float = 0.0
var old_dir : Vector2 = Vector2.ZERO
var prev_smoothed_pos: Vector2 = Vector2.ZERO
var has_prev = false
var rot_drag : float = 0.0
var follow_point_rot : float = 0.0
var last_target_angle : float= 0.0
var has_last_target : bool = false
var biased : float = 0.0
var strength = 0.0
var _b : float = 0.0
var lock_movement : bool = false
var dragger
var rotation_node
var pos_node
var mouse_rot
var sprite_node
var last_wobble_pos := Vector2.ZERO
var paused_wobble := Vector2.ZERO

func _ready() -> void:
	dragger = %Dragger
	rotation_node = %Rotation
	pos_node = %Pos
	mouse_rot = %MouseRot
	sprite_node = %Sprite2D

func _physics_process(delta: float) -> void:
	applied_pos = Vector2(0.0,0.0)
	applied_rotation = 0.0
	applied_scale = Vector2(1.0, 1.0)
	if not Global.static_view:
		if actor.get_value("should_rotate"):
			auto_rotate()
		else:
			%Pos.rotation = 0.0
		rainbow(delta)
		movements(delta)
	else:
		static_prev()
	follow_wiggle(delta)
	%Rotation.rotation = GlobalCalculations.is_nan_or_inf(applied_rotation + rot_drag + follow_point_rot)
	%Pos.position += GlobalCalculations.is_nan_or_inf(applied_pos)
	placeholder_position = %Pos.global_position

func movements(delta):
	if !Global.static_view:
		glob = %Dragger.global_position
		if actor.get_value("static_obj"):
			var static_pos = Global.sprite_container.get_parent().get_parent().to_global(actor.get_value("position"))
			%Drag.global_position = static_pos
		else:
			drag(delta)
		wobble(delta)
		if actor.get_value("ignore_bounce"):
			glob.y -= Global.sprite_container.bounceChange
			
		var length = (glob.y - %Dragger.global_position.y)
		
		if actor.get_value("physics"):
			if (actor.get_parent() is Sprite2D && is_instance_valid(actor.get_parent())) or (actor.get_parent() is WigglyAppendage2D && is_instance_valid(actor.get_parent())):
				var c_parent = actor.get_parent().owner
				if c_parent != null && is_instance_valid(c_parent):
					var c_parrent_length = (c_parent.get_node("%Movements").glob.y - c_parent.get_node("%Pos").global_position.y)
					var c_parrent_length2 = (c_parent.get_node("%Movements").glob.x - c_parent.get_node("%Pos").global_position.x)
					length += c_parrent_length + c_parrent_length2
			
		rotationalDrag(length, delta)
		stretch(length)

func drag(_delta):
	if actor.get_value("dragSpeed") == 0:
		%Dragger.global_position = placeholder_position
	else:
		%Dragger.global_position = lerp(%Dragger.global_position, placeholder_position,1/max(actor.get_value("dragSpeed"), 1))
		%Drag.global_position = %Dragger.global_position


func wobble(delta: float) -> void:
	if actor.is_default("xFrq"):
		if actor.get_value("pause_movement"):
			if actor.is_all_default("xFrq"):
				last_wobble_pos.x = 0
			else:
				paused_wobble.x += delta if Global.settings_dict.should_delta else 1.
		else:
			last_wobble_pos.x = sin((Global.tick-paused_wobble.x)*actor.get_value("xFrq"))*actor.get_value("xAmp")
	else:
		last_wobble_pos.x = sin((Global.tick)*actor.get_value("xFrq"))*actor.get_value("xAmp")
	
	if actor.is_default("yFrq"):
		if actor.get_value("pause_movement"):
			if actor.is_all_default("yFrq"):
				last_wobble_pos.y = 0
				print("d")
			else:
				paused_wobble.y += delta if Global.settings_dict.should_delta else 1.
		else:
			last_wobble_pos.y = sin((Global.tick-paused_wobble.y)*actor.get_value("yFrq"))*actor.get_value("yAmp")
	else:
		last_wobble_pos.y = sin((Global.tick)*actor.get_value("yFrq"))*actor.get_value("yAmp")
	
	
	applied_pos.x += last_wobble_pos.x
	applied_pos.y += last_wobble_pos.y

var paused_rotation: float = 0
var last_rot: float = 0
func rotationalDrag(length, delta: float):
	if actor.is_default("rot_frq"):
		if actor.get_value("pause_movement"):
			if actor.is_all_default("rot_frq"):
				last_rot = 0
			else:
				paused_rotation += delta if Global.settings_dict.should_delta else 1.
		else:
			last_rot = sin((Global.tick-paused_rotation) * actor.get_value("rot_frq"))
			last_rot *= deg_to_rad(actor.get_value("rdragStr"))
	else:
		last_rot = sin((Global.tick-paused_rotation) * actor.get_value("rot_frq"))
		last_rot *= deg_to_rad(actor.get_value("rdragStr"))
	
	applied_rotation = lerp_angle(applied_rotation, last_rot, 0.15)
	
	var yvel = ((length * actor.get_value("rdragStr"))* 0.5)
	yvel = clamp(yvel,actor.get_value("rLimitMin"),actor.get_value("rLimitMax"))
	
	rot_drag = GlobalCalculations.is_nan_or_inf(lerp_angle(rot_drag,deg_to_rad(yvel),0.15))

func stretch(length):
	var yvel = (length * actor.get_value("stretchAmount") * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)
	
	%Rotation.scale = lerp(%Rotation.scale,target,0.15)

func static_prev():
	%Pos.position = Vector2(0,0)
	%Pos.rotation = 0.0
	%Drag.rotation = 0.0
	%Sprite2D.self_modulate = actor.get_value("tint")
	%Pos.modulate.s = 0
	%Dragger.global_position = %Pos.global_position
	%Rotation.rotation = 0.0
	%Rotation.scale = Vector2(1,1)
	%Drag.scale = Vector2(1,1)
	%MouseRot.rotation = 0.0

func follow_wiggle(delta: float) -> void:
	if not actor.get_value("follow_wa_tip"):
		follow_point_rot = 0.0
		return
	var parent := actor.get_parent()
	if !is_instance_valid(parent) or !(parent is WigglyAppendage2D):
		follow_point_rot = 0.0
		return
	
	var tip_index = clamp(actor.get_value("tip_point"), 0, parent.points.size() - 1)
	var raw_tip: Vector2 = parent.points[tip_index]
	var rest_angle: float = parent._rest_direction_angle
	var smoothed_pos = actor.position.lerp(raw_tip, 0.9)
	actor.position = smoothed_pos
	var base_length: float = 1.0
	if parent.points.size() > 1:
		base_length = max(parent.points[0].distance_to(parent.points[-1]), 0.001)
	if has_prev:
		var movement = smoothed_pos - prev_smoothed_pos
		var raw_strength = movement.length() / (base_length * max(delta, 0.0001))
		strength = lerp(strength, clamp(raw_strength, 0.0, 1.0), 0.1)
	prev_smoothed_pos = smoothed_pos
	has_prev = true
	var dir = prev_smoothed_pos  - raw_tip
	var min_angle = deg_to_rad(actor.get_value("follow_wa_mini"))
	var max_angle = deg_to_rad(actor.get_value("follow_wa_max"))
	var dir_angle = atan2(dir.y, dir.x)
	
	if dir.length() > actor.get_value("rotation_threshold"):
		if actor.get_value("anchor_id") == null:
			if actor.get_value("follow_range"):
				var rel_angle = wrapf(dir_angle - rest_angle, -PI, PI)
				var target_rel: float = rel_angle * strength
				var target_ang: float = rest_angle + target_rel  
				min_angle += rest_angle 
				max_angle += rest_angle  
				_b = target_ang
			else:
				var rel_angle = wrapf(dir_angle, -PI, PI)
				var target_rel: float = rel_angle * strength
				var target_ang: float = target_rel  
				_b = target_ang
		
		biased = lerp(biased,_b, actor.get_value("follow_strength"))
	follow_point_rot = GlobalCalculations.clamp_angle(biased, min_angle, max_angle)

func rainbow(delta):
	if actor.get_value("hidden_item") && Global.mode != 0:
		%Sprite2D.self_modulate.a = 0.0
	else:
		if actor.get_value("rainbow"):
			if not actor.get_value("rainbow_self"):
				%Sprite2D.self_modulate.s = 0
				%Pos.modulate.s = 1
				%Pos.modulate.h = wrap(%Pos.modulate.h + (actor.get_value("rainbow_speed")*delta), 0, 1)
			else:
				%Pos.modulate.s = 0
				%Sprite2D.self_modulate.s = 1
				%Sprite2D.self_modulate.h = wrap(%Sprite2D.self_modulate.h + (actor.get_value("rainbow_speed")*delta), 0, 1)
		else:
			%Sprite2D.self_modulate = actor.get_value("tint")
			%Pos.modulate.s = 0

func auto_rotate():
	%Pos.rotate(actor.get_value("should_rot_speed"))
	%Pos.rotation = GlobalCalculations.is_nan_or_inf(%Pos.rotation)


func _on_sprite_object_visibility_changed() -> void:
	pass
	#set_physics_process(actor.is_visible_in_tree())
