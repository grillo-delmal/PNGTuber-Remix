extends Node

func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullify)
	nullify()

func enable() -> void:
	var sp: SpriteObject = null
	if Global.held_sprites:
		sp = Global.held_sprites[0]
	
	if !is_instance_valid(sp):
		nullify()
		return
	%FollowOption.disabled = false
	%FollowOption.select(sp.get_value("follow_type"))

func nullify() -> void:
	%FollowOption.disabled = true


func _on_follow_option_item_selected(index: int) -> void:
	for i in Global.held_sprites:
		i.sprite_data["follow_type"] = index 
		StateButton.multi_edit(i.sprite_data["follow_type"], "follow_type", i, i.states)
		i.save_state(Global.current_state)
