extends Node

@export var actor : Node2D
var glob : Vector2 = Vector2.ZERO
var last_mouse_position : Vector2 = Vector2(0,0)
var last_dist : Vector2 = Vector2(0,0)
var mouse : Vector2 = Vector2(0,0)
var vel = Vector2.ZERO
var distance : Vector2 = Vector2.ZERO
var mouse_moving

func _ready() -> void:
	Global.update_mouse_vel_pos.connect(mouse_delay)

func _process(delta: float) -> void:
	if !Global.static_view:
		if actor.sprite_data.should_rotate:
			auto_rotate()
		else:
			%Wobble.rotation = 0
		rainbow()
		
		movements(delta)
		follow_mouse(delta)
		
	else:
		static_prev()
	
	follow_wiggle()

func movements(delta):
	if !Global.static_view:
		glob = %Dragger.global_position
		if actor.sprite_data.static_obj:
			var static_pos = Global.sprite_container.get_parent().get_parent().to_global(actor.sprite_data.position)
			%Dragger.global_position = static_pos
			%Drag.global_position = %Dragger.global_position
		else:
			drag(delta)
		
		
		wobble()
		if actor.sprite_data.ignore_bounce:
			glob.y -= Global.sprite_container.bounceChange
		
		var length = (glob.y - %Dragger.global_position.y)
		
		if actor.sprite_data.physics:
			if (actor.get_parent() is Sprite2D && is_instance_valid(actor.get_parent())) or (actor.get_parent() is WigglyAppendage2D && is_instance_valid(actor.get_parent())):
				var c_parent = actor.get_parent().owner
				if c_parent != null && is_instance_valid(c_parent):
					var c_parrent_length = (c_parent.get_node("%Movements").glob.y - c_parent.get_node("%Drag").global_position.y)
					var c_parrent_length2 = (c_parent.get_node("%Movements").glob.x - c_parent.get_node("%Drag").global_position.x)
					length += c_parrent_length + c_parrent_length2
			
		rotationalDrag(length, delta)
		stretch(length, delta)

func drag(_delta):
	if actor.sprite_data.dragSpeed == 0:
		%Dragger.global_position = %Wobble.global_position
	else:
		%Dragger.global_position = lerp(%Dragger.global_position,%Wobble.global_position,1/actor.sprite_data.dragSpeed)
		%Drag.global_position = %Dragger.global_position

func wobble():
	%Wobble.position.x = lerp(%Wobble.position.x, sin(Global.tick*actor.sprite_data.xFrq)*actor.sprite_data.xAmp, 0.15)
	%Wobble.position.y = lerp(%Wobble.position.y, sin(Global.tick*actor.sprite_data.yFrq)*actor.sprite_data.yAmp, 0.15)

func rotationalDrag(length,_delta):
	%Drag.rotation = sin(Global.tick*actor.sprite_data.rot_frq)*deg_to_rad(actor.sprite_data.rdragStr)
	var yvel = ((length * actor.sprite_data.rdragStr)* 0.5)
	
	#Calculate Max angle
	
	yvel = clamp(yvel,actor.sprite_data.rLimitMin,actor.sprite_data.rLimitMax)
	
	%Rotation.rotation = lerp_angle(%Rotation.rotation,deg_to_rad(yvel),0.08)

func stretch(length,_delta):
	var yvel = (length * actor.sprite_data.stretchAmount * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)
	
	%Squish.scale = lerp(%Squish.scale,target,0.1)

func static_prev():
	%Pos.position = Vector2(0,0)
	%Sprite2D.self_modulate = actor.sprite_data.tint
	%Pos.modulate.s = 0
	%Wobble.rotation = 0
	%Wobble.position = Vector2(0,0)
	%Squish.scale = Vector2(1,1)
	%Dragger.global_position = %Wobble.global_position
	%Rotation.rotation = 0.0
	%Drag.rotation = 0.0
	%Drag.scale = Vector2(1,1)
	%Squish.rotation = 0.0

func follow_wiggle():
	if actor.sprite_data.follow_wa_tip:
		if actor.get_parent() is WigglyAppendage2D && is_instance_valid(actor.get_parent()):
			var pnt = actor.get_parent().points[clamp(actor.sprite_data.tip_point,0, actor.get_parent().points.size() -1)]
			actor.position = actor.position.lerp(pnt, 0.6)
			%Pos.rotation = lerp(%Pos.rotation, clamp(actor.position.angle(), deg_to_rad(actor.sprite_data.follow_wa_mini), deg_to_rad(actor.sprite_data.follow_wa_max)),0.08)
		else:
			%Pos.rotation = 0
		
	else:
		%Pos.rotation = 0

func rainbow():
	if actor.sprite_data.rainbow:
		if not actor.sprite_data.rainbow_self:
			%Sprite2D.self_modulate.s = 0
			%Pos.modulate.s = 1
			%Pos.modulate.h = wrap(%Pos.modulate.h + actor.sprite_data.rainbow_speed, 0, 1)
		else:
			%Pos.modulate.s = 0
			%Sprite2D.self_modulate.s = 1
			%Sprite2D.self_modulate.h = wrap(%Sprite2D.self_modulate.h + actor.sprite_data.rainbow_speed, 0, 1)
	else:
		%Sprite2D.self_modulate = actor.sprite_data.tint
		%Pos.modulate.s = 0

func mouse_delay():
	var mouse_delta = last_mouse_position - mouse
	if !mouse_delta.is_zero_approx():
		distance = Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))
		last_mouse_position = mouse  # Only update when there's actual movement

func follow_mouse(_delta):
	var main_marker = Global.main.get_node("%Marker")
	if main_marker.current_screen != main_marker.ALL_SCREENS_ID:
		if !main_marker.mouse_in_current_screen():
			mouse = Vector2.ZERO
		else:
			var viewport_size = actor.get_viewport().size
			var origin = actor.get_global_transform_with_canvas().origin
			var x_per = 1.0 - origin.x/float(viewport_size.x)
			var y_per = 1.0 - origin.y/float(viewport_size.y)
			var display_size = DisplayServer.screen_get_size(main_marker.current_screen)
			var offset = Vector2(display_size.x * x_per, display_size.y * y_per)
			var mouse_pos = DisplayServer.mouse_get_position() - DisplayServer.screen_get_position(main_marker.current_screen)
			mouse = Vector2(mouse_pos - display_size) + offset 
	else:
		mouse = actor.get_local_mouse_position()
	if actor.sprite_data.follow_mouse_velocity:
	#	mouse_delay()
		var mouse_delta = last_mouse_position - mouse
		if abs(Vector2(tanh(mouse_delta.x), tanh(mouse_delta.y))) > Vector2(0.5, 0.5):
			vel = lerp(vel, -(Vector2(actor.sprite_data.look_at_mouse_pos,actor.sprite_data.look_at_mouse_pos_y)*distance), 0.15)
			var dir = Vector2.ZERO.direction_to(vel)
			var dist = vel.limit_length(Vector2(actor.sprite_data.look_at_mouse_pos,actor.sprite_data.look_at_mouse_pos_y).length()).length()
			last_dist = Vector2(dir.x * (dist),dir.y * (dist))
				
		%Pos.position.x = lerp(%Pos.position.x, last_dist.x, actor.sprite_data.mouse_delay)
		%Pos.position.y = lerp(%Pos.position.y, last_dist.y, actor.sprite_data.mouse_delay)
		
		var mouse_x = mouse.x
		var screen_width = get_viewport().size.x
		# Calculate the normalized mouse position (-1 to 1, where 0 is center)
		var normalized_mouse = (mouse_x - screen_width / 2) / (screen_width / 2)

		# Map the normalized position to the rotation factor
		var rotation_factor = lerp(actor.sprite_data.mouse_rotation_max, actor.sprite_data.mouse_rotation, (normalized_mouse + 1) / 2)

		# Calculate the target rotation, scaled by the factor and clamped
		var target_rotation = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(actor.sprite_data.rLimitMin), deg_to_rad(actor.sprite_data.rLimitMax))

		# Smoothly interpolate the sprite's rotation
		%Squish.rotation = lerp_angle(%Squish.rotation, target_rotation, actor.sprite_data.mouse_delay)
		var dire = Vector2.ZERO - (last_mouse_position - main_marker.coords)
		var scl_x = abs(dire.x) *actor.sprite_data.mouse_scale_x *0.005
		var scl_y = abs(dire.y) *actor.sprite_data.mouse_scale_y *0.005
		%Drag.scale.x = lerp(%Drag.scale.x, float(clamp(1 - scl_x, 0.15 , 1)), actor.sprite_data.mouse_delay)
		%Drag.scale.y = lerp(%Drag.scale.y, float(clamp(1 - scl_y,  0.15 , 1)), actor.sprite_data.mouse_delay)
		
	else:
		var dir = distance.direction_to(mouse)
		var dist = mouse.length()
		%Pos.position.x = lerp(%Pos.position.x, dir.x * min(dist, actor.sprite_data.look_at_mouse_pos), actor.sprite_data.mouse_delay)
		%Pos.position.y = lerp(%Pos.position.y, dir.y * min(dist, actor.sprite_data.look_at_mouse_pos_y), actor.sprite_data.mouse_delay)
		
		# Get the mouse position and screen width
		var mouse_x = mouse.x
		var screen_width = get_viewport().size.x

		# Calculate the normalized mouse position (-1 to 1, where 0 is center)
		var normalized_mouse = (mouse_x - screen_width / 2) / (screen_width / 2)

		# Map the normalized position to the rotation factor
		var rotation_factor = lerp(actor.sprite_data.mouse_rotation_max, actor.sprite_data.mouse_rotation, (normalized_mouse + 1) / 2)

		# Calculate the target rotation, scaled by the factor and clamped
		var target_rotation = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(actor.sprite_data.rLimitMin), deg_to_rad(actor.sprite_data.rLimitMax))

		# Smoothly interpolate the sprite's rotation
		%Squish.rotation = lerp_angle(%Squish.rotation, target_rotation, actor.sprite_data.mouse_delay)
#		print(clamping)
		var dire = Vector2.ZERO - main_marker.coords
		var scl_x = (abs(dire.x) *actor.sprite_data.mouse_scale_x *0.005) * Global.settings_dict.zoom.x
		var scl_y = (abs(dire.y) *actor.sprite_data.mouse_scale_y *0.005) * Global.settings_dict.zoom.y
		%Drag.scale.x = lerp(%Drag.scale.x, float(clamp(1 - scl_x, 0.15 , 1)), actor.sprite_data.mouse_delay)
		%Drag.scale.y = lerp(%Drag.scale.y, float(clamp(1 - scl_y,  0.15 , 1)), actor.sprite_data.mouse_delay)


func auto_rotate():
	%Wobble.rotate(actor.sprite_data.should_rot_speed)
