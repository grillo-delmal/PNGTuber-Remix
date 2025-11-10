extends Node

@export var actor : SpriteObject


var last_mouse_position : Vector2 = Vector2.ZERO
var last_dist : Vector2 = Vector2.ZERO
var mouse_coords : Vector2 = Vector2.ZERO
var vel : Vector2 = Vector2.ZERO
var distance : Vector2 = Vector2.ZERO
var dir_vel_anim : Vector2 = Vector2.ZERO
var dist_vel_anim : float = 0.0
var frame_h : float = 0.0
var frame_v : float = 0.0

var target_x : float = 0
var target_y : float = 0
var target_rotation_axis : Vector2 = Vector2.ZERO
var target_scale_axis : Vector2 = Vector2.ZERO

var pos_node
var mouse_rot
var drag_node
var sprite_node
var rest : bool = false


func _ready() -> void:
	pos_node = %Pos
	mouse_rot = %MouseRot
	drag_node = %Drag
	sprite_node = %Sprite2D
	Global.update_mouse_vel_pos.connect(mouse_delay)

func _physics_process(delta: float) -> void:
	if not Global.static_view or actor.rest_mode != 5:
		if (actor.rest_mode == 1 or actor.rest_mode == 3) && rest:
			%Pos.position = Vector2.ZERO
		else:
			follow_calculation(delta)
	else:
		%Pos.position = Vector2.ZERO
		%MouseRot.rotation = 0.0
		%Drag.scale = Vector2(1,1)

func mouse_delay():
	var mouse_delta = last_mouse_position - mouse_coords
	if not mouse_delta.is_zero_approx():
		distance = Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))
		if distance.length() != distance.length(): # check for NAN
			distance = Vector2.ZERO
		last_mouse_position = mouse_coords

func follow_calculation(_delta):
	var main_marker = Global.main.get_node("%Marker")

	if main_marker.current_screen != main_marker.ALL_SCREENS:
		if !main_marker.mouse_in_current_screen() && Global.settings_dict.snap_out_of_bounds:
			mouse_coords = Vector2.ZERO
		else:
			var viewport_size = actor.get_viewport().size
			var origin = actor.sprite_object.get_global_transform_with_canvas().origin
			var x_per = 1.0 - origin.x/float(viewport_size.x)
			var y_per = 1.0 - origin.y/float(viewport_size.y)
			var offset = Vector2( x_per, y_per)
			var mouse_pos = actor.sprite_object.get_local_mouse_position()
			mouse_coords = Vector2(mouse_pos - Vector2(DisplayServer.screen_get_position(main_marker.current_screen))) + offset 
	else:
		mouse_coords = actor.sprite_object.get_local_mouse_position()
	
	var dir = distance.direction_to(mouse_coords)
	var dist = mouse_coords.length()
	
	follow_stuff(mouse_coords, main_marker, dir, dist)

func follow_position(dir, dist, axis_left, axis_right, axis_shoulderl, axis_shoulderr,axis_lr_3):
	if actor.get_value("follow_type") == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_mouse_vel_position()
			follow_sprite_anim(dir_vel_anim, dist_vel_anim)
		else:
			follow_mouse_position(dir, dist)
			follow_sprite_anim(dir, dist)
	elif actor.get_value("follow_type") == 1 or actor.get_value("follow_type") == 2:
		var position_follow = GlobalCalculations.follow_type_helper("follow_type", actor, "position", axis_left, axis_right, self)
		follow_controller_position(position_follow.axis, position_follow.axis.x * actor.get_value("look_at_mouse_pos"), position_follow.axis.y * actor.get_value("look_at_mouse_pos_y"))
		follow_sprite_anim(position_follow.axis, position_follow.dist)
	elif actor.get_value("follow_type") == 9 or actor.get_value("follow_type") == 10:
		var position_follow = GlobalCalculations.follow_type_helper("follow_type", actor, "position", axis_shoulderl, axis_shoulderr, self)
		follow_controller_position(position_follow.axis, position_follow.axis.x * actor.get_value("look_at_mouse_pos"), position_follow.axis.y * actor.get_value("look_at_mouse_pos_y"))
		follow_sprite_anim(position_follow.axis, position_follow.dist)
	elif actor.get_value("follow_type") in [3,4,5,6,7,8]:
		var pos_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type", actor)
		if actor.get_value("snap_pos"):
			target_x = lerp(target_x, pos_axis.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay")) if pos_axis.x != 0 else target_x
			target_y = lerp(target_y, pos_axis.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay")) if pos_axis.y != 0 else target_y
		else:
			target_x = pos_axis.x * actor.get_value("look_at_mouse_pos")
			target_y = pos_axis.y * actor.get_value("look_at_mouse_pos_y")
		var dist_mouse = Vector2(target_x, target_y).length()
		follow_controller_position(pos_axis, target_x, target_y)
		follow_sprite_anim(pos_axis, dist_mouse)
	elif actor.get_value("follow_type") == 11:
		if actor.get_value("snap_pos"):
			target_x = lerp(target_x, axis_lr_3.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay")) if axis_lr_3.x != 0 else axis_lr_3
			target_y = lerp(target_y, axis_lr_3.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay")) if axis_lr_3.y != 0 else axis_lr_3
		else:
			target_x = axis_lr_3.x * actor.get_value("look_at_mouse_pos")
			target_y = axis_lr_3.y * actor.get_value("look_at_mouse_pos_y")
		var dist_lr = Vector2(target_x, target_y).length()
		follow_controller_position(axis_lr_3, target_x, target_y)
		follow_sprite_anim(axis_lr_3, dist_lr)
		
	else:
		%Pos.position = Vector2.ZERO
		return

func follow_rotation(mouse, main_marker , axis_left, axis_right, axis_shoulderl, axis_shoulderr,axis_lr_3):
	if actor.get_value("follow_type2") == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_mouse_vel_rotation()
		else:
			follow_mouse_rotation(mouse, main_marker)
	elif actor.get_value("follow_type2") == 1 or actor.get_value("follow_type2") == 2:
		var rotation_axis = GlobalCalculations.follow_type_helper("follow_type2", actor, "angle", axis_left, axis_right, self)
		follow_controller_rotation(rotation_axis.axis)
	elif actor.get_value("follow_type2") == 9 or actor.get_value("follow_type2") == 10:
		var rotation_axis = GlobalCalculations.follow_type_helper("follow_type2", actor, "angle", axis_shoulderl, axis_shoulderr, self)
		follow_controller_rotation(rotation_axis.axis)
	elif actor.get_value("follow_type2") in [3,4,5,6,7,8]:
		var rotation_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type2", actor)
		target_rotation_axis = target_rotation_axis.lerp(rotation_axis, 0.15) if actor.get_value("snap_rot") and not rotation_axis.is_zero_approx() else rotation_axis
		follow_controller_rotation(target_rotation_axis)
	elif actor.get_value("follow_type2") == 11:
		target_rotation_axis = target_rotation_axis.lerp(axis_lr_3, 0.15) if actor.get_value("snap_rot") and not axis_lr_3.is_zero_approx() else axis_lr_3
		follow_controller_rotation(target_rotation_axis)
	else:
		%MouseRot.rotation = 0.0
		return

func follow_scale(mouse, main_marker, axis_left, axis_right, axis_shoulderl, axis_shoulderr,axis_lr_3):
	if actor.get_value("follow_type3") == 0:
		if actor.get_value("follow_mouse_velocity"):
			follow_mouse_vel_scale()
		else:
			follow_mouse_scale(mouse, main_marker)
	elif actor.get_value("follow_type3") == 1 or actor.get_value("follow_type3") == 2:
		var scale_axis = GlobalCalculations.follow_type_helper("follow_type3", actor, "scale", axis_left, axis_right, self)
		follow_controller_scale(scale_axis.axis)
	elif actor.get_value("follow_type3") == 9 or actor.get_value("follow_type3") == 10:
		var scale_axis = GlobalCalculations.follow_type_helper("follow_type3", actor, "scale", axis_shoulderl, axis_shoulderr, self)
		follow_controller_scale(scale_axis.axis)
	elif actor.get_value("follow_type3") in [3,4,5,6,7,8]:
		var scale_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type3", actor)
		target_scale_axis = target_scale_axis.lerp(scale_axis, 0.15) if actor.get_value("snap_scale") and scale_axis.is_zero_approx() else scale_axis
		follow_controller_scale(target_scale_axis)
	elif actor.get_value("follow_type3") == 11:
		target_scale_axis = target_scale_axis.lerp(axis_lr_3, 0.15) if actor.get_value("snap_scale") and axis_lr_3.is_zero_approx() else axis_lr_3
		follow_controller_scale(target_scale_axis)
	else:
		%Drag.position = Vector2.ZERO
		return

func follow_stuff(mouse, main_marker, dir, dist):
	if actor.get_value("follow_mouse_velocity"):
		var mouse_delta = last_mouse_position - mouse
		var delta_abs = Vector2(abs(tanh(mouse_delta.x)), abs(tanh(mouse_delta.y)))
		if delta_abs.x > 0.5 or delta_abs.y > 0.5:
			var look = Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
			vel = lerp(vel, -look * distance, 0.15)
			var dir_vel = vel.normalized()
			var dist_vel = min(vel.length(), look.length())
			dist_vel_anim = dist_vel
			last_dist = dir_vel * dist_vel
			dir_vel_anim = mouse_delta
	
	var axis_left = Input.get_vector("ControllerLeft", "ControllerRight", "ControllerUp", "ControllerDown")
	var axis_right = Input.get_vector("ControllerFour", "ControllerTwo", "ControllerOne", "ControllerThree")
	var axis_shoulderl = Input.get_vector("ShoulderL1", "ShoulderR1", "ShoulderL1", "ShoulderR1")
	var axis_shoulderr = Input.get_vector("ShoulderL2", "ShoulderR2", "ShoulderL2", "ShoulderR2")
	var axis_lr_3 = Input.get_vector("L3", "R3", "L3", "R3")
	follow_position(dir, dist, axis_left, axis_right, axis_shoulderl, axis_shoulderr, axis_lr_3)
	follow_rotation(mouse, main_marker , axis_left, axis_right, axis_shoulderl, axis_shoulderr, axis_lr_3)
	follow_scale(mouse, main_marker, axis_left, axis_right, axis_shoulderl, axis_shoulderr, axis_lr_3)

func follow_mouse_vel_position():
	var target = last_dist
	if actor.sprite_type == "Sprite2D" and actor.get_value("non_animated_sheet") and actor.get_value("animate_to_mouse") and not actor.get_value("animate_to_mouse_track_pos"):
		target = Vector2.ZERO
	%Pos.position.x = GlobalCalculations.is_nan_or_inf(lerp(%Pos.position.x, target.x, actor.get_value("mouse_delay")))
	%Pos.position.y = GlobalCalculations.is_nan_or_inf(lerp(%Pos.position.y, target.y, actor.get_value("mouse_delay")))

func follow_mouse_vel_rotation():
	var normalized_mouse = clamp((-dir_vel_anim.x / 2), -1.0, 1.0)
	var rotation_factor = lerp(actor.get_value("mouse_rotation_max"), actor.get_value("mouse_rotation"), max(normalized_mouse / 2, 0.01))
	var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	var target_rotation = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))
	%MouseRot.rotation = GlobalCalculations.is_nan_or_inf(lerp_angle(%MouseRot.rotation, target_rotation, actor.get_value("mouse_delay")))

func follow_mouse_vel_scale():
	var t = dir_vel_anim.normalized() / 2
	var norm_x = clamp(abs(t.x), 0.0, 1.0)
	var norm_y = clamp(abs(t.y), 0.0, 1.0)
	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x"), max(norm_x, 0.01))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.01))
	%Drag.scale.x = GlobalCalculations.is_nan_or_inf(lerp(%Drag.scale.x, target_scale_x, actor.get_value("mouse_delay")), true)
	%Drag.scale.y = GlobalCalculations.is_nan_or_inf(lerp(%Drag.scale.y, target_scale_y, actor.get_value("mouse_delay")), true)

func follow_mouse_position(dir, dist):
	var target = Vector2(dir.x * min(dist, actor.get_value("look_at_mouse_pos")), dir.y * min(dist, actor.get_value("look_at_mouse_pos_y")))
	if actor.sprite_type == "Sprite2D" and actor.get_value("non_animated_sheet") and actor.get_value("animate_to_mouse") and not actor.get_value("animate_to_mouse_track_pos"):
		target = Vector2.ZERO
	%Pos.position.x = GlobalCalculations.is_nan_or_inf(lerp(%Pos.position.x, target.x, actor.get_value("mouse_delay")))
	%Pos.position.y = GlobalCalculations.is_nan_or_inf(lerp(%Pos.position.y, target.y, actor.get_value("mouse_delay")))
	if actor.get_value("look_at_mouse_pos") == 0:
		%Pos.position.x = target.x
	if actor.get_value("look_at_mouse_pos_y") == 0:
		%Pos.position.y = target.y

func follow_mouse_rotation(mouse, main_marker):
	var screen_size = DisplayServer.screen_get_size(main_marker.current_screen if main_marker.current_screen != Monitor.ALL_SCREENS else 1)
	var normalized_mouse = clamp(mouse.x / (screen_size.x / 2), -1.0, 1.0)
	var rotation_factor = lerp(actor.sprite_data.mouse_rotation, actor.sprite_data.mouse_rotation_max, max((normalized_mouse + 1) / 2, 0.001))
	var safe_rot_min = clamp(actor.sprite_data.rLimitMin, -360, 360)
	var safe_rot_max = clamp(actor.sprite_data.rLimitMax, -360, 360)
	var target_rotation = clamp(rotation_factor, deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))
	%MouseRot.rotation = GlobalCalculations.is_nan_or_inf(lerp_angle(%MouseRot.rotation, target_rotation, actor.get_value("mouse_delay")))

func follow_mouse_scale(mouse, main_marker):
	var screen_size = DisplayServer.screen_get_size(main_marker.current_screen if main_marker.current_screen != Monitor.ALL_SCREENS else 1)
	var center = screen_size * 0.5
	var norm_x = clamp(abs(mouse.x) / center.x, 0.0, 1.0)
	var norm_y = clamp(abs(mouse.y) / center.y, 0.0, 1.0)
	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x"), max(norm_x, 0.001))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.001))
	%Drag.scale.x = GlobalCalculations.is_nan_or_inf(target_scale_x, true)
	%Drag.scale.y = GlobalCalculations.is_nan_or_inf(target_scale_y, true)

func follow_controller_position(_axis, t_x, t_y):
	if actor.sprite_type == "Sprite2D" and actor.get_value("non_animated_sheet") and actor.get_value("animate_to_mouse") and not actor.get_value("animate_to_mouse_track_pos"):
		%Pos.position.x = lerp(%Pos.position.x, 0.0, actor.get_value("mouse_delay"))
		%Pos.position.y = lerp(%Pos.position.y, 0.0, actor.get_value("mouse_delay"))
	else:
		%Pos.position.x = lerp(%Pos.position.x, t_x, actor.get_value("mouse_delay"))
		%Pos.position.y = lerp(%Pos.position.y, t_y, actor.get_value("mouse_delay"))

	if actor.get_value("look_at_mouse_pos") == 0:
		%Pos.position.x = 0.0
	if actor.get_value("look_at_mouse_pos_y") == 0:
		%Pos.position.y = 0.0

func follow_controller_rotation(axis):
	var normalized = clamp(axis.x, -1.0, 1.0)
	var rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	var rotation_factor = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), max((normalized + 1) / 2, 0.001))
	var target_rotation = clamp(rotation_factor, deg_to_rad(rot_min), deg_to_rad(rot_max))
	%MouseRot.rotation = lerp_angle(%MouseRot.rotation, target_rotation, actor.get_value("mouse_delay"))

func follow_controller_scale(axis):
	var norm_x = clamp(abs(axis.x), 0.0, 1.0)
	var norm_y = clamp(abs(axis.y), 0.0, 1.0)
	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x"), max(norm_x, 0.001))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.001))
	%Drag.scale.x = lerp(%Drag.scale.x, target_scale_x, actor.get_value("mouse_delay"))
	%Drag.scale.y = lerp(%Drag.scale.y, target_scale_y, actor.get_value("mouse_delay"))

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


func _on_sprite_object_visibility_changed() -> void:
	rest = !actor.is_visible_in_tree()
