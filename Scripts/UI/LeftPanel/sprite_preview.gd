extends HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.deselect.connect(nullfy)
	Global.reinfo.connect(enable)
	nullfy()


func nullfy():
	%CurrentSelected.texture = null
	%CurrentSelectedNormal.texture = null
	

func enable():
	if Global.held_sprites.size() == 1:
		if not Global.held_sprites[0].get_value("folder"):
			%CurrentSelectedNormal.texture = Global.held_sprites[0].get_node("%Sprite2D").texture.normal_texture
			%CurrentSelected.texture = Global.held_sprites[0].get_node("%Sprite2D").texture.diffuse_texture
		else:
			%CurrentSelected.texture = null
			%CurrentSelectedNormal.texture = null
	else:
		%CurrentSelected.texture = null
		%CurrentSelectedNormal.texture = null
