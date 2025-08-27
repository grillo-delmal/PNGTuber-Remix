extends Node2D



func _physics_process(delta: float) -> void:
	%Sprite2D.position.x = sin(3*Global.tick)*10 * 3
	%Sprite2D2.global_transform = %Sprite2D.global_transform
	%Sprite2D3.position.y = sin(2*Global.tick)*5 *2
	%Sprite2D3.rotation = sin(2*Global.tick)*1 *2
	%Sprite2D4.global_transform = %Sprite2D3.global_transform
	%Sprite2D5.position.x = sin(4*Global.tick)*8 * 4
