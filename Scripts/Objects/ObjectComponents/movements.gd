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


func _ready() -> void:
	Global.update_mouse_vel_pos.connect(mouse_delay)

func _process(delta: float) -> void:
	applied_pos = Vector2(0.0,0.0)
	applied_rotation = 0.0
	applied_scale = Vector2(1.0, 1.0)
	if !Global.static_view:
		if actor.get_value("should_rotate"):
			auto_rotate()
		else:
			%Pos.rotation = 0.0
		rainbow()
		follow_mouse(delta)
		movements(delta)
	else:
		static_prev()
	
	follow_wiggle()
	
	%Rotation.rotation = is_nan_or_inf(clamp(applied_rotation, deg_to_rad(-360), deg_to_rad(360)))
	%Pos.position += is_nan_or_inf(applied_pos)

func movements(delta):
	if !Global.static_view:
		glob = %Dragger.global_position
		if actor.get_value("static_obj"):
			var static_pos = Global.sprite_container.get_parent().get_parent().to_global(actor.get_value("position"))
			%Dragger.global_position = static_pos
			%Drag.global_position = %Dragger.global_position
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
		stretch(length, delta)

func drag(_delta):
	if actor.get_value("dragSpeed") == 0:
		%Dragger.global_position = %Pos.global_position
	else:
		%Dragger.global_position = lerp(%Dragger.global_position, %Pos.global_position,1/max(actor.get_value("dragSpeed"), 1))
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
		last_wobble_pos.x = sin((Global.tick-paused_wobble.x)*actor.get_value("xFrq"))*actor.get_value("xAmp")
	
	if actor.is_default("yFrq"):
		if actor.get_value("pause_movement"):
			if actor.is_all_default("yFrq"):
				last_wobble_pos.y = 0
			else:
				paused_wobble.y += delta if Global.settings_dict.should_delta else 1.
		else:
			last_wobble_pos.y = sin((Global.tick-paused_wobble.y)*actor.get_value("yFrq"))*actor.get_value("yAmp")
	else:
		last_wobble_pos.y = sin((Global.tick-paused_wobble.y)*actor.get_value("yFrq"))*actor.get_value("yAmp")
	
	applied_pos.x = lerp(applied_pos.x, last_wobble_pos.x, 0.15)
	applied_pos.y = lerp(applied_pos.y, last_wobble_pos.y, 0.15)

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
	
	applied_rotation = is_nan_or_inf(lerp_angle(applied_rotation,deg_to_rad(yvel),0.08))

func stretch(length,_delta):
	var yvel = (length * actor.get_value("stretchAmount") * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)
	
	%Rotation.scale = lerp(%Rotation.scale,target,0.1)

func static_prev():
	%Pos.position = Vector2(0,0)
	%Drag.rotation = 0.0
	%Sprite2D.self_modulate = actor.get_value("tint")
	%Pos.modulate.s = 0
	%Dragger.global_position = %Pos.global_position
	%Rotation.rotation = 0.0
	%Rotation.scale = Vector2(1,1)
	%Drag.scale = Vector2(1,1)

func follow_wiggle():
	if actor.get_value("follow_wa_tip"):
		if actor.get_parent() is WigglyAppendage2D && is_instance_valid(actor.get_parent()):
			var pnt = actor.get_parent().points[clamp(actor.get_value("tip_point"),0, actor.get_parent().points.size() -1)]
			actor.position = actor.position.lerp(pnt, 0.6)
			applied_rotation += is_nan_or_inf(clamp(atan2(actor.position.y* pnt.y, actor.position.x* pnt.x)*0.15, deg_to_rad(actor.get_value("follow_wa_mini")), deg_to_rad(actor.get_value("follow_wa_max"))))

func rainbow():
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

func mouse_delay():
	var mouse_delta = last_mouse_position - mouse_coords
	if !mouse_delta.is_zero_approx():
		distance = Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))
		if distance.length() == NAN:
			distance = Vector2(0.0, 0.0)
		last_mouse_position = mouse_coords  # Only update when there's actual movement

var global_mouse := Vector2.ZERO
func follow_mouse(_delta):
	var main_marker = Global.main.get_node("%Marker")
	
	if WindowHandler.windows:
		mouse_coords = Vector2.ZERO
		if main_marker.current_screen == Monitor.ALL_SCREENS or main_marker.mouse_in_current_screen():
			mouse_coords = DisplayServer.mouse_get_position() - WindowHandler.windows[0].position
	
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
	
	if actor.get_value("follow_mouse_velocity"):
		follow_mouse_vel(mouse_coords, main_marker)
	else:
		follow_mouse_normal(mouse_coords, main_marker, dir, dist)
		follow_mouse_sprite_anim(dir, dist)

func follow_mouse_vel(mouse, main_marker):
#	mouse_delay()
	var mouse_delta = last_mouse_position - mouse
	if abs(Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))) > Vector2(0.5, 0.5):
		var look := Vector2(actor.get_value("look_at_mouse_pos"),actor.get_value("look_at_mouse_pos_y"))
		vel = lerp(vel, -look*distance, 0.15)
		var dir = Vector2.ZERO.direction_to(vel)
		var dist = vel.limit_length(look.length()).length()
		last_dist = Vector2(dir.x * (dist),dir.y * (dist))
		follow_mouse_sprite_anim(dir, dist)
	
	
	if actor.sprite_type == "Sprite2D":
		if actor.get_value("non_animated_sheet") && actor.get_value("animate_to_mouse") && !actor.get_value("animate_to_mouse_track_pos"):
			applied_pos.x = is_nan_or_inf(lerp(%Pos.position.x, 0.0, actor.get_value("mouse_delay")))
			applied_pos.y = is_nan_or_inf(lerp(%Pos.position.y, 0.0, actor.get_value("mouse_delay")))
		else:
			applied_pos.x = is_nan_or_inf(lerp(%Pos.position.x, last_dist.x, actor.get_value("mouse_delay")))
			applied_pos.y = is_nan_or_inf(lerp(%Pos.position.y, last_dist.y, actor.get_value("mouse_delay")))
	else:
		applied_pos.x = is_nan_or_inf(lerp(%Pos.position.x, last_dist.x, actor.get_value("mouse_delay")))
		applied_pos.y = is_nan_or_inf(lerp(%Pos.position.y, last_dist.y, actor.get_value("mouse_delay")))

	var mouse_x = mouse.x
	var screen_width = get_viewport().size.x
	# Calculate the normalized mouse position (-1 to 1, where 0 is center)
	var normalized_mouse = (mouse_x - screen_width / 2) / (screen_width / 2)

	# Map the normalized position to the rotation factor
	var rotation_factor = lerp(actor.get_value("mouse_rotation_max"), actor.get_value("mouse_rotation"), max(0.01, (normalized_mouse + 1) / 2))

	var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
	# Calculate the target rotation, scaled by the factor and clamped
	var target_rotation = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))

	# Smoothly interpolate the sprite's rotation
	applied_rotation = is_nan_or_inf(lerp_angle(%Rotation.rotation, target_rotation, actor.get_value("mouse_delay")))
	
	var screen_size = DisplayServer.screen_get_size(-1)
	if main_marker.current_screen == Monitor.ALL_SCREENS:
		screen_size = DisplayServer.screen_get_size(1)
	else:
		screen_size = DisplayServer.screen_get_size(main_marker.current_screen)
		
	var center = screen_size * 0.5
	var dist_from_center = last_dist - main_marker.coords
	var norm_x = clamp(abs(dist_from_center.x) / center.x, 0.0, 1.0)
	var norm_y = clamp(abs(dist_from_center.y) / center.y, 0.0, 1.0)
	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x") , max(norm_x, 0.01))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.01))
	%Drag.scale.x = is_nan_or_inf(lerp(%Drag.scale.x, target_scale_x, actor.get_value("mouse_delay")), true)
	%Drag.scale.y = is_nan_or_inf(lerp(%Drag.scale.y, target_scale_y, actor.get_value("mouse_delay")), true)

func follow_mouse_normal(mouse, main_marker, dir, dist):
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
		
	var screen_size = DisplayServer.screen_get_size(-1)
	if main_marker.current_screen == Monitor.ALL_SCREENS:
		screen_size = DisplayServer.screen_get_size(1)
	else:
		screen_size = DisplayServer.screen_get_size(main_marker.current_screen)
	
	var mouse_x = mouse.x
	var screen_width = screen_size.x
	var normalized_mouse = (mouse_x) / (screen_width / 2)
	normalized_mouse = clamp(normalized_mouse, -1.0, 1.0)
	
	var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
	var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)

	var rotation_factor = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), max((normalized_mouse + 1) / 2, 0.001))

	var target_rotation = clamp(rotation_factor, deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))

	applied_rotation = is_nan_or_inf(lerp_angle(%Rotation.rotation, target_rotation, actor.get_value("mouse_delay")))

	if applied_rotation == NAN:
		applied_rotation = 0.0

	var center = screen_size * 0.5
	var dist_from_center = mouse
	var norm_x = clamp(abs(dist_from_center.x) / center.x, 0.0, 1.0)
	var norm_y = clamp(abs(dist_from_center.y) / center.y, 0.0, 1.0)
	var target_scale_x = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x") , max(norm_x, 0.001))
	var target_scale_y = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), max(norm_y, 0.001))
	%Drag.scale.x = is_nan_or_inf(lerp(%Drag.scale.x, target_scale_x, actor.get_value("mouse_delay")), true)
	%Drag.scale.y = is_nan_or_inf(lerp(%Drag.scale.y, target_scale_y, actor.get_value("mouse_delay")), true)

func follow_mouse_sprite_anim(dir, dist):
	if actor.sprite_type == "Sprite2D":
		if actor.get_value("non_animated_sheet") && actor.get_value("animate_to_mouse"):
			
			var dist_x = dir.x * min(dist, actor.get_value("look_at_mouse_pos"))
			var dist_y = dir.y * min(dist, actor.get_value("look_at_mouse_pos_y"))
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
			%Sprite2D.frame_coords.x = floor(move_toward(%Sprite2D.frame_coords.x, float(frame_x), actor.get_value("animate_to_mouse_speed")))
			%Sprite2D.frame_coords.y = floor(move_toward(%Sprite2D.frame_coords.y, float(frame_y), actor.get_value("animate_to_mouse_speed")))

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
