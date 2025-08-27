extends Node

@export var actor : SpriteObject
var glob : Vector2 = Vector2.ZERO
var last_mouse_position : Vector2 = Vector2(0,0)
var last_dist : Vector2 = Vector2(0,0)
var mouse_coords : Vector2 = Vector2(0,0)
var vel = Vector2.ZERO
var distance : Vector2 = Vector2.ZERO
var mouse_moving
var frame = 0
var frame2 = 0
var applied_pos = Vector2(0.0,0.0)
var applied_rotation = 0.0
var applied_scale = Vector2(1.0, 1.0)
var placeholder_position : Vector2 = Vector2.ZERO
var controller_vel : Vector2 = Vector2.ZERO
var target_x : float = 0
var target_y  : float = 0
var target_rotation_axis : Vector2 = Vector2.ZERO
var target_scale_axis : Vector2 = Vector2.ZERO

var dir_vel_anim : Vector2 = Vector2.ZERO
var dist_vel_anim : float = 0.0
var frame_h : float = 0.0
var frame_v : float = 0.0

var vector_l_r : Vector2 = Vector2.ZERO
var vector_u_d : Vector2 = Vector2.ZERO
var clamped_angle : float = 0.0
var target_angle : float = 0.0
var old_dir : Vector2 = Vector2.ZERO

var prev_smoothed_pos: Vector2 = Vector2.ZERO
var has_prev := false

#pls work, 
var rot_drag : float = 0.0
var follow_point_rot : float = 0.0
var last_target_angle : float= 0.0 
var has_last_target : float = false
var biased : float = 0.0
var strength = 0.0
var _b : float = 0.0


func _ready() -> void:
	Global.update_mouse_vel_pos.connect(mouse_delay)

func _physics_process(delta: float) -> void:
	applied_pos = Vector2(0.0,0.0)
	applied_rotation = 0.0
	applied_scale = Vector2(1.0, 1.0)
	if !Global.static_view:
		if actor.get_value("should_rotate"):
			auto_rotate()
		else:
			%Pos.rotation = 0.0
		rainbow()
		follow_calculation(delta)
		movements(delta)
	else:
		static_prev()
	
	follow_wiggle(delta)
	

	%Rotation.rotation = is_nan_or_inf(applied_rotation + rot_drag + follow_point_rot)
	%Pos.position += is_nan_or_inf(applied_pos)
	placeholder_position = %Pos.global_position

#region Parameter Movement
func movements(delta):
	if !Global.static_view:
		glob = %Dragger.global_position
		if actor.get_value("static_obj"):
			var static_pos = Global.sprite_container.get_parent().get_parent().to_global(actor.get_value("position"))
			#%Dragger.global_position = static_pos
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
		#printt(%Dragger.global_position, %Drag.global_position)

func drag(_delta):
	if actor.get_value("dragSpeed") == 0:
		%Dragger.global_position = placeholder_position
	else:
		%Dragger.global_position = lerp(%Dragger.global_position, placeholder_position,1/max(actor.get_value("dragSpeed"), 1))
		%Drag.global_position = %Dragger.global_position

var last_wobble_pos := Vector2.ZERO
var paused_wobble := Vector2.ZERO
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
	
	#Calculate Max angle
	
	yvel = clamp(yvel,actor.get_value("rLimitMin"),actor.get_value("rLimitMax"))
	
	rot_drag = is_nan_or_inf(lerp_angle(rot_drag,deg_to_rad(yvel),0.15))

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

	follow_point_rot = clamp_angle(biased, min_angle, max_angle)
	

func clamp_angle(value: float, min_angle: float, max_angle: float, rest: float = 0.0) -> float:
	var v = value + rest
	var n = min_angle + rest
	var m = max_angle + rest
	if n <= m:
		if v < n: return n
		if v > m: return m
		return v
	else:
		if v > m and v < n:
			var dist_min = abs(_get_distance(v, n))
			var dist_max = abs(_get_distance(v, m))
			return n if dist_min < dist_max else m
		return v

func _get_distance(a: float, b: float) -> float:
	return a - b

#if actor.is_visible_in_tree():
	#printt(min_ang, max_ang)

func rainbow():
	if actor.get_value("hidden_item") && Global.mode != 0:
		%Sprite2D.self_modulate.a = 0.0
	else:
		if actor.get_value("rainbow"):
			if not actor.get_value("rainbow_self"):
				%Sprite2D.self_modulate.s = 0
				%Pos.modulate.s = 1
				%Pos.modulate.h = wrap(%Pos.modulate.h + actor.get_value("rainbow_speed"), 0, 1)
			else:
				%Pos.modulate.s = 0
				%Sprite2D.self_modulate.s = 1
				%Sprite2D.self_modulate.h = wrap(%Sprite2D.self_modulate.h + actor.get_value("rainbow_speed"), 0, 1)
		else:
			%Sprite2D.self_modulate = actor.get_value("tint")
			%Pos.modulate.s = 0

#endregion

#region Follow Type Movement
func mouse_delay():
	var mouse_delta = last_mouse_position - mouse_coords
	if !mouse_delta.is_zero_approx():
		distance = Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))
		if distance.length() == NAN:
			distance = Vector2(0.0, 0.0)
		last_mouse_position = mouse_coords  # Only update when there's actual movement

var global_mouse := Vector2.ZERO
func follow_calculation(_delta):
	var main_marker = Global.main.get_node("%Marker")
	
	if WindowHandler.windows:
		mouse_coords = Vector2.ZERO
		if main_marker.current_screen == Monitor.ALL_SCREENS or main_marker.mouse_in_current_screen():
			mouse_coords = DisplayServer.mouse_get_position()
	
	elif main_marker.current_screen != Monitor.ALL_SCREENS:
		if !main_marker.mouse_in_current_screen():
			mouse_coords = Vector2.ZERO
		else:
			var viewport_size = actor.get_viewport().size
			var origin = actor.get_global_transform_with_canvas().origin
			var x_per = 1.0 - origin.x/float(viewport_size.x)
			var y_per = 1.0 - origin.y/float(viewport_size.y)
			var display_size = DisplayServer.screen_get_size(main_marker.current_screen)
			var offset = Vector2(display_size.x * x_per, display_size.y * y_per)
			var mouse_pos = DisplayServer.mouse_get_position() - DisplayServer.screen_get_position(main_marker.current_screen)
			mouse_coords = Vector2(mouse_pos - display_size) + offset 
	else:
		mouse_coords = actor.get_local_mouse_position()
	
	var dir = distance.direction_to(mouse_coords)
	var dist = mouse_coords.length()
	
	
	follow_mouse(mouse_coords, main_marker, dir, dist)
	follow_controller()
	follow_keyboard()

func follow_mouse(mouse, main_marker, dir, dist):
	if actor.get_value("follow_mouse_velocity"):
		var mouse_delta = last_mouse_position - mouse
		if abs(Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))) > Vector2(0.5, 0.5):
			var look := Vector2(actor.get_value("look_at_mouse_pos"),actor.get_value("look_at_mouse_pos_y"))
			vel = lerp(vel, -look*distance, 0.15)
			var dir_vel = Vector2.ZERO.direction_to(vel)
			var dist_vel  = vel.limit_length(look.length()).length()
			dist_vel_anim = dist_vel
			last_dist = Vector2(dir_vel.x * (dist_vel),dir_vel.y * (dist_vel))
			dir_vel_anim = mouse_delta
			
		
	
	if actor.get_value("follow_type") == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_mouse_vel_position()
			follow_sprite_anim(dir_vel_anim, dist_vel_anim)
		else:
			follow_mouse_position(dir, dist)
			follow_sprite_anim(dir, dist)
	
	if actor.get_value("follow_type2") == 0:
		if actor.get_value("follow_mouse_velocity"):
			pass
			follow_mouse_vel_rotation()
		else:
			follow_mouse_rotation(mouse ,main_marker)

	if actor.get_value("follow_type3") == 0:
		if actor.get_value("follow_mouse_velocity"):
			pass
			follow_mouse_vel_scale()
		else:
			follow_mouse_scale(mouse, main_marker)


#region Follow Mouse Velocity

func follow_mouse_vel_position():
	if actor.sprite_type == "Sprite2D":
		if actor.get_value("non_animated_sheet") && actor.get_value("animate_to_mouse") && !actor.get_value("animate_to_mouse_track_pos"):
			%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, 0.0, actor.get_value("mouse_delay")))
			%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, 0.0, actor.get_value("mouse_delay")))
		else:
			%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, last_dist.x, actor.get_value("mouse_delay")))
			%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, last_dist.y, actor.get_value("mouse_delay")))
	else:
		%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, last_dist.x, actor.get_value("mouse_delay")))
		%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, last_dist.y, actor.get_value("mouse_delay")))

func follow_mouse_vel_rotation():
	var t = Vector2(-dir_vel_anim.x, 0).normalized()
	var normalized_mouse = t.x/2
	normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
	var rotation_factor = lerp(actor.get_value("mouse_rotation_max"), actor.get_value("mouse_rotation"), max(0.01, (normalized_mouse) / 2))
	var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	var target_rotation = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))
	%MouseRot.rotation = is_nan_or_inf(lerp_angle(%MouseRot.rotation, target_rotation, actor.get_value("mouse_delay")))

func follow_mouse_vel_scale():
	var t = dir_vel_anim.normalized()
	var normalized_mouse = t/2

	var norm_x = clamp(abs(normalized_mouse.x), 0.0, 1.0)
	var norm_y = clamp(abs(normalized_mouse.y), 0.0, 1.0)

	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x") , max(norm_x, 0.01))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.01))
	%Drag.scale.x = is_nan_or_inf(lerp(%Drag.scale.x, target_scale_x, actor.get_value("mouse_delay")), true)
	%Drag.scale.y = is_nan_or_inf(lerp(%Drag.scale.y, target_scale_y, actor.get_value("mouse_delay")), true)
#endregion

#region Follow Mouse (Normal)
func follow_mouse_position(dir, dist):
	if actor.sprite_type == "Sprite2D":
		if actor.get_value("non_animated_sheet") && actor.get_value("animate_to_mouse") && !actor.get_value("animate_to_mouse_track_pos"):
			%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, 0.0, actor.get_value("mouse_delay")))
			%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, 0.0, actor.get_value("mouse_delay")))
		else:
			%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, dir.x * min(dist, actor.get_value("look_at_mouse_pos")), actor.get_value("mouse_delay")))
			%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, dir.y * min(dist, actor.get_value("look_at_mouse_pos_y")), actor.get_value("mouse_delay")))
	else:
		%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, dir.x * min(dist, actor.get_value("look_at_mouse_pos")), actor.get_value("mouse_delay")))
		%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, dir.y * min(dist, actor.get_value("look_at_mouse_pos_y")), actor.get_value("mouse_delay")))
	
	if actor.get_value("look_at_mouse_pos") == 0:
		%Pos.position.x = dir.x * min(dist, actor.get_value("look_at_mouse_pos"))
	if actor.get_value("look_at_mouse_pos_y") == 0:
		%Pos.position.y = dir.y * min(dist, actor.get_value("look_at_mouse_pos_y"))

func follow_mouse_rotation(mouse ,main_marker):
	var screen_size = DisplayServer.screen_get_size(-1)
	if main_marker.current_screen == Monitor.ALL_SCREENS:
		screen_size = DisplayServer.screen_get_size(1)
	else:
		screen_size = DisplayServer.screen_get_size(main_marker.current_screen)
	
	
	var mouse_x = mouse.x
	var screen_width = screen_size.x
	# Calculate the normalized mouse position (-1 to 1, where 0 is center)
	var normalized_mouse = (mouse_x) / (screen_width / 2)
	normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
	
	var safe_rot_min = clamp(actor.sprite_data.rLimitMin, -360, 360)
	var safe_rot_max = clamp(actor.sprite_data.rLimitMax, -360, 360)
	# Map the normalized position to the rotation factor
	var rotation_factor = lerp(actor.sprite_data.mouse_rotation, actor.sprite_data.mouse_rotation_max, max((normalized_mouse + 1) / 2, 0.001))
	# Calculate the target rotation, scaled by the factor and clamped
	var target_rotation = clamp(rotation_factor, deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))

	%MouseRot.rotation = is_nan_or_inf(lerp_angle(%MouseRot.rotation, target_rotation, actor.get_value("mouse_delay")))

	if applied_rotation == NAN:
		applied_rotation = 0.0

func follow_mouse_scale(mouse, main_marker):
	var screen_size = DisplayServer.screen_get_size(-1)
	if main_marker.current_screen == Monitor.ALL_SCREENS:
		screen_size = DisplayServer.screen_get_size(1)
	else:
		screen_size = DisplayServer.screen_get_size(main_marker.current_screen)
	
	var center = screen_size * 0.5
	var dist_from_center = mouse
	var norm_x = clamp(abs(dist_from_center.x) / center.x, 0.0, 1.0)
	var norm_y = clamp(abs(dist_from_center.y) / center.y, 0.0, 1.0)
	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x") , max(norm_x, 0.001))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.001))
	%Drag.scale.x = is_nan_or_inf(lerp(%Drag.scale.x, target_scale_x, actor.get_value("mouse_delay")), true)
	%Drag.scale.y = is_nan_or_inf(lerp(%Drag.scale.y, target_scale_y, actor.get_value("mouse_delay")), true)

#endregion

#region Controller Movement
func follow_controller():
	var axis_left = Input.get_vector("ControllerLeft", "ControllerRight", "ControllerUp", "ControllerDown")
	var axis_right = Input.get_vector("ControllerFour", "ControllerTwo", "ControllerOne", "ControllerThree")
	
	if actor.get_value("follow_type") == 1:
		if actor.get_value("snap_pos"):
			if axis_left.x != 0:
				target_x = lerp(target_x, axis_left.x * actor.get_value("look_at_mouse_pos"),actor.get_value("mouse_delay"))
			if axis_left.y != 0 && actor.get_value("snap_pos"):
				target_y = lerp(target_y, axis_left.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
		else:
			target_x = axis_left.x * actor.get_value("look_at_mouse_pos")
			target_y = axis_left.y * actor.get_value("look_at_mouse_pos_y")
		var dist = Vector2(target_x, target_y).length()
		follow_controller_position(axis_left, target_x, target_y)
		follow_sprite_anim(axis_left, dist)
	elif actor.get_value("follow_type") == 2:
		if actor.get_value("snap_pos"):
			if axis_right.x != 0:
				target_x = lerp(target_x, (axis_right.x * actor.get_value("look_at_mouse_pos")), actor.get_value("mouse_delay"))
			if axis_right.y != 0 && actor.get_value("snap_pos"):
				target_y = lerp(target_y, axis_right.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
		else:
			target_x = axis_right.x * actor.get_value("look_at_mouse_pos")
			target_y = axis_right.y * actor.get_value("look_at_mouse_pos_y")
		var dist = Vector2(target_x, target_y).length()
		follow_controller_position(axis_right, target_x, target_y)
		follow_sprite_anim(axis_right, dist)
	
	if actor.get_value("follow_type2") == 1:
		follow_controller_rotation(axis_left)
	elif actor.get_value("follow_type2") == 2:
		follow_controller_rotation(axis_right)

	if actor.get_value("follow_type3") == 1:
		follow_controller_scale(axis_left)
	elif actor.get_value("follow_type3") == 2:
		follow_controller_scale(axis_right)

func follow_controller_position(_axis, t_x, t_y):
	if actor.sprite_type == "Sprite2D":
		if actor.get_value("non_animated_sheet") && actor.get_value("animate_to_mouse") && !actor.get_value("animate_to_mouse_track_pos"):
			%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, 0.0, actor.get_value("mouse_delay")))
			%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, 0.0, actor.get_value("mouse_delay")))
		else:
			%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, t_x, actor.get_value("mouse_delay")))
			%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, t_y, actor.get_value("mouse_delay")))
	else:
			
		%Pos.position.x = is_nan_or_inf(lerp(%Pos.position.x, t_x, actor.get_value("mouse_delay")))
		%Pos.position.y = is_nan_or_inf(lerp(%Pos.position.y, t_y, actor.get_value("mouse_delay")))

	if actor.get_value("look_at_mouse_pos") == 0:
		%Pos.position.x = 0.0
	if actor.get_value("look_at_mouse_pos_y") == 0:
		%Pos.position.y = 0.0

func follow_controller_rotation(axis):
	var normalized_mouse = clamp(axis.x, -1.0, 1.0)
	var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	var rotation_factor = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), max((normalized_mouse + 1) / 2, 0.001))
	var target_rotation = clamp(rotation_factor, deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))
	%MouseRot.rotation = is_nan_or_inf(lerp_angle(%MouseRot.rotation, target_rotation, actor.get_value("mouse_delay")))
	if applied_rotation == NAN:
		applied_rotation = 0.0

func follow_controller_scale(axis):
	var norm_x = clamp(abs(axis.x), 0.0, 1.0)
	var norm_y = clamp(abs(axis.y), 0.0, 1.0)
	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x") , max(norm_x, 0.001))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.001))
	%Drag.scale.x = is_nan_or_inf(lerp(%Drag.scale.x, target_scale_x, actor.get_value("mouse_delay")), true)
	%Drag.scale.y = is_nan_or_inf(lerp(%Drag.scale.y, target_scale_y, actor.get_value("mouse_delay")), true)

#endregion

func follow_keyboard():
	if actor.get_value("follow_type") in [3,4,5,6,7,8]:
		var pos_axis = some_keyboard_calc_wasd()
	
		if actor.get_value("snap_pos"):
			if pos_axis.x != 0:
				target_x = lerp(target_x, pos_axis.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay"))
			if pos_axis.y != 0 && actor.get_value("snap_pos"):
				target_y = lerp(target_y, pos_axis.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
		else:
			target_x = pos_axis.x * actor.get_value("look_at_mouse_pos")
			target_y = pos_axis.y * actor.get_value("look_at_mouse_pos_y")
		var dist = Vector2(target_x, target_y).length()
		follow_controller_position(pos_axis , target_x, target_y)
		follow_sprite_anim(pos_axis, dist)

	if actor.get_value("follow_type2") in [3,4,5,6,7,8]:
		var rotaion_axis = some_keyboard_calc_wasd("follow_type2")
		if actor.get_value("snap_rot"):
			if !rotaion_axis.is_zero_approx():
				target_rotation_axis = target_rotation_axis.lerp(rotaion_axis, 0.15)
		else:
			target_rotation_axis = rotaion_axis
		follow_controller_rotation(target_rotation_axis)

	if actor.get_value("follow_type3") in [3,4,5,6,7,8]:
		var scale_axis = some_keyboard_calc_wasd("follow_type3")
		if actor.get_value("snap_rot"):
			if scale_axis.is_zero_approx():
				target_scale_axis = target_scale_axis.lerp(scale_axis, 0.15)
		else:
			target_scale_axis = scale_axis
		
		follow_controller_scale(target_scale_axis)

func some_keyboard_calc_wasd(type_name : String = "follow_type") -> Vector2:
	var normal = Vector2(0.0, 0.0)
	if actor.get_value(type_name) in [3,4,5]:
		var ws : Vector2 = Vector2.ZERO
		var ad : Vector2 = Vector2.ZERO
		if InputMap.action_get_events("KeyMovementW")[0].as_text() in GlobalInputCapture.already_input_keys:
			ws.y = 1.0
		if InputMap.action_get_events("KeyMovementS")[0].as_text() in GlobalInputCapture.already_input_keys:
			ws.x = 1.0
		if InputMap.action_get_events("KeyMovementA")[0].as_text() in GlobalInputCapture.already_input_keys:
			ad.y = 1.0
		if InputMap.action_get_events("KeyMovementD")[0].as_text() in GlobalInputCapture.already_input_keys:
			ad.x = 1.0
		
		if actor.get_value(type_name) == 3:
			normal = Vector2(ws.x - ws.y, ws.x - ws.y)
		elif actor.get_value(type_name) == 4:
			normal = Vector2(ad.x - ad.y, ad.x - ad.y)
		elif actor.get_value(type_name) == 5:
			normal = Vector2(ad.x - ad.y, ws.x - ws.y)
	
	elif actor.get_value(type_name) in [6,7,8]:
		var ws : Vector2 = Vector2.ZERO
		var ad : Vector2 = Vector2.ZERO
		if InputMap.action_get_events("KeyMovementW")[1].as_text() in GlobalInputCapture.already_input_keys:
			ws.y = 1.0
		if InputMap.action_get_events("KeyMovementS")[1].as_text() in GlobalInputCapture.already_input_keys:
			ws.x = 1.0
		if InputMap.action_get_events("KeyMovementA")[1].as_text() in GlobalInputCapture.already_input_keys:
			ad.y = 1.0
		if InputMap.action_get_events("KeyMovementD")[1].as_text() in GlobalInputCapture.already_input_keys:
			ad.x = 1.0

		if actor.get_value(type_name) == 6:
			normal = Vector2(ws.x - ws.y, ws.x - ws.y)
		elif actor.get_value(type_name) == 7:
			normal = Vector2(ad.x - ad.y, ad.x - ad.y)
		elif actor.get_value(type_name) == 8:
			normal = Vector2(ad.x - ad.y, ws.x - ws.y)

	return normal

func follow_sprite_anim(dir, dist):
	if actor.sprite_type == "Sprite2D":
		if actor.get_value("non_animated_sheet") && actor.get_value("animate_to_mouse"):
			
			var new_dir = dir
			
			var dist_x = new_dir.x * min(dist, actor.get_value("look_at_mouse_pos"))
			var dist_y = new_dir.y * min(dist, actor.get_value("look_at_mouse_pos_y"))
			var max_dist_x = actor.get_value("look_at_mouse_pos")
			var max_dist_y = actor.get_value("look_at_mouse_pos_y")
			var hframes = %Sprite2D.hframes
			var vframes = %Sprite2D.vframes
			var normalized_x = (dist_x / (2.0 * max_dist_x)) + 0.5
			var normalized_y = (dist_y / (2.0 * max_dist_y)) + 0.5
			var raw_frame_x = (normalized_x * hframes)
			var raw_frame_y = (normalized_y * vframes)
			if sign(actor.get_value("look_at_mouse_pos")) == -1:
				raw_frame_x = hframes - (normalized_x * hframes)
			if sign(actor.get_value("look_at_mouse_pos_y")) == -1:
				raw_frame_y = vframes - (normalized_y * vframes)
			var frame_x = clamp(floor(raw_frame_x), 0, hframes - 1)
			var frame_y = clamp(floor(raw_frame_y), 0, vframes - 1)
			frame_h = move_toward(frame_h, float(frame_x), actor.get_value("animate_to_mouse_speed"))
			frame_v = move_toward(frame_v, float(frame_y), actor.get_value("animate_to_mouse_speed"))
			%Sprite2D.frame_coords.x = floor(frame_h)
			%Sprite2D.frame_coords.y = floor(frame_v)

#endregion

func auto_rotate():
	%Pos.rotate(actor.get_value("should_rot_speed"))
	%Pos.rotation = is_nan_or_inf(%Pos.rotation)

func is_nan_or_inf(value, should_be_one = false):
	if (value is int) or (value is float):
		if is_inf(value):
			if should_be_one:
				value = 1.0
			else:
				value = 0.0
		if is_nan(value):
			if should_be_one:
				value = 1.0
			else:
				value = 0.0
		return value
		
	elif (value is Vector2) or (value is Vector2i):
		if is_inf(value.x):
			if should_be_one:
				value.x = 1.0
			else:
				value.x = 0.0
		if is_nan(value.x):
			if should_be_one:
				value.x = 1.0
			else:
				value.x = 0.0
		if is_inf(value.y):
			if should_be_one:
				value.y = 1.0
			else:
				value.y = 0.0
		if is_nan(value.y):
			if should_be_one:
				value.y = 1.0
			else:
				value.y = 0.0
		return value
	else:
		return value
