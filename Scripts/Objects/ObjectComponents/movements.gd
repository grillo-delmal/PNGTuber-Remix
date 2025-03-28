extends Node

@export var actor : Node
var glob : Vector2 = Vector2.ZERO
var last_mouse_position : Vector2 = Vector2(0,0)
var last_dist : Vector2 = Vector2(0,0)

func _process(delta: float) -> void:
	if !Global.static_view:
		if actor.dictmain.should_rotate:
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
		drag(delta)
		wobble()
		if actor.dictmain.ignore_bounce:
			glob.y -= Global.sprite_container.bounceChange
		
		var length = (glob.y - %Dragger.global_position.y)
		
		if actor.dictmain.physics:
			if (actor.get_parent() is Sprite2D && is_instance_valid(actor.get_parent())) or (actor.get_parent() is WigglyAppendage2D && is_instance_valid(actor.get_parent())):
				var c_parent = actor.get_parent().owner
				if c_parent != null && is_instance_valid(c_parent):
					var c_parrent_length = (c_parent.get_node("%Movements").glob.y - c_parent.get_node("%Drag").global_position.y)
					var c_parrent_length2 = (c_parent.get_node("%Movements").glob.x - c_parent.get_node("%Drag").global_position.x)
					length += c_parrent_length + c_parrent_length2
			
		rotationalDrag(length, delta)
		stretch(length, delta)

func drag(_delta):
	if actor.dictmain.dragSpeed == 0:
		%Dragger.global_position = %Wobble.global_position
	else:
		%Dragger.global_position = lerp(%Dragger.global_position,%Wobble.global_position,1/actor.dictmain.dragSpeed)
		%Drag.global_position = %Dragger.global_position

func wobble():
	%Wobble.position.x = lerp(%Wobble.position.x, sin(Global.tick*actor.dictmain.xFrq)*actor.dictmain.xAmp, 0.15)
	%Wobble.position.y = lerp(%Wobble.position.y, sin(Global.tick*actor.dictmain.yFrq)*actor.dictmain.yAmp, 0.15)

func rotationalDrag(length,_delta):
	%Drag.rotation = sin(Global.tick*actor.dictmain.rot_frq)*deg_to_rad(actor.dictmain.rdragStr)
	var yvel = ((length * actor.dictmain.rdragStr)* 0.5)
	
	#Calculate Max angle
	
	yvel = clamp(yvel,actor.dictmain.rLimitMin,actor.dictmain.rLimitMax)
	
	%Rotation.rotation = lerp_angle(%Rotation.rotation,deg_to_rad(yvel),0.15)

func stretch(length,_delta):
	var yvel = (length * actor.dictmain.stretchAmount * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)
	
	%Squish.scale = lerp(%Squish.scale,target,0.1)


func static_prev():
	%Pos.position = Vector2(0,0)
	%Sprite2D.self_modulate = actor.dictmain.tint
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
	if actor.dictmain.follow_wa_tip:
		if actor.get_parent() is WigglyAppendage2D && is_instance_valid(actor.get_parent()):
			var pnt = actor.get_parent().points[clamp(actor.dictmain.tip_point,0, actor.get_parent().points.size() -1)]
			actor.position = pnt
			%Pos.rotation = clamp(pnt.y/80, deg_to_rad(actor.dictmain.follow_wa_mini), deg_to_rad(actor.dictmain.follow_wa_max))
		else:
			%Pos.rotation = 0
		
	else:
		%Pos.rotation = 0

func rainbow():
	if actor.dictmain.rainbow:
		if not actor.dictmain.rainbow_self:
			%Sprite2D.self_modulate.s = 0
			%Pos.modulate.s = 1
			%Pos.modulate.h = wrap(%Pos.modulate.h + actor.dictmain.rainbow_speed, 0, 1)
		else:
			%Pos.modulate.s = 0
			%Sprite2D.self_modulate.s = 1
			%Sprite2D.self_modulate.h = wrap(%Sprite2D.self_modulate.h + actor.dictmain.rainbow_speed, 0, 1)
	else:
		%Sprite2D.self_modulate = actor.dictmain.tint
		%Pos.modulate.s = 0

func follow_mouse(delta):
	var main_marker = get_tree().get_root().get_node("Main/%Marker")
	var mouse
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
	if actor.dictmain.follow_mouse_velocity:
		var distance = last_mouse_position - mouse
		if !distance.is_zero_approx():
			var vel = -(distance/delta)
			var dir = Vector2.ZERO.direction_to(vel)
			var dist = vel.length()
			last_dist = Vector2(dir.x * min(dist, actor.dictmain.look_at_mouse_pos),dir.y * min(dist, actor.dictmain.look_at_mouse_pos_y))
		%Pos.position.x = lerp(%Pos.position.x, last_dist.x, 0.1)
		%Pos.position.y = lerp(%Pos.position.y, last_dist.y, 0.1)
		var clamping = clamp(last_dist.angle()*actor.dictmain.mouse_rotation,deg_to_rad(actor.dictmain.rLimitMin),deg_to_rad(actor.dictmain.rLimitMax))
		%Squish.rotation = lerp_angle(%Squish.rotation ,clamping,0.1)
		var dire = Vector2.ZERO - (last_mouse_position - main_marker.coords)
		var scl_x = abs(dire.x) *actor.dictmain.mouse_scale_x *0.005
		var scl_y = abs(dire.y) *actor.dictmain.mouse_scale_y *0.005
		%Drag.scale.x = lerp(%Drag.scale.x, float(clamp(1 - scl_x, 0.15 , 1)), 0.1)
		%Drag.scale.y = lerp(%Drag.scale.y, float(clamp(1 - scl_y,  0.15 , 1)), 0.1)
		last_mouse_position = mouse
	else:
		var dir = Vector2.ZERO.direction_to(mouse)
		var dist = mouse.length()
		%Pos.position.x = lerp(%Pos.position.x, dir.x * min(dist, actor.dictmain.look_at_mouse_pos), 0.1)
		%Pos.position.y = lerp(%Pos.position.y, dir.y * min(dist, actor.dictmain.look_at_mouse_pos_y), 0.1)
		var clamping = clamp(mouse.angle()*actor.dictmain.mouse_rotation,deg_to_rad(actor.dictmain.rLimitMin),deg_to_rad(actor.dictmain.rLimitMax))
		%Squish.rotation = lerp_angle(%Squish.rotation ,clamping,0.1)
#		print(clamping)
		var dire = Vector2.ZERO - main_marker.coords
		var scl_x = (abs(dire.x) *actor.dictmain.mouse_scale_x *0.005) * Global.settings_dict.zoom.x
		var scl_y = (abs(dire.y) *actor.dictmain.mouse_scale_y *0.005) * Global.settings_dict.zoom.y
		%Drag.scale.x = lerp(%Drag.scale.x, float(clamp(1 - scl_x, 0.15 , 1)), 0.1)
		%Drag.scale.y = lerp(%Drag.scale.y, float(clamp(1 - scl_y,  0.15 , 1)), 0.1)

func auto_rotate():
	%Wobble.rotate(actor.dictmain.should_rot_speed)
