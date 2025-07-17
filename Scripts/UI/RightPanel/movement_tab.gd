extends Node
class_name Movement

enum FollowMouse {
	Enabled,
	Disabled,
	OnMouthOpen,
	OnMouthClosed
}

@onready var select_follow: MenuButton = %SelectFollowMouseEnabled


func _ready() -> void:
	select_follow.get_popup().id_pressed.connect(_on_enabled_selected)
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	nullfy()

func enable() -> void:
	for i in Global.held_sprites:
		select_follow.disabled = false
		select_follow.text = select_follow.get_popup().get_item_text(i.sprite_data.mouse_follow)
		break

func nullfy() -> void:
	select_follow.text = "Always"
	select_follow.disabled = true

func _on_enabled_selected(id) -> void:
	select_follow.text = select_follow.get_popup().get_item_text(id)
	
	var undo_redo_data : Array = []
	for i in Global.held_sprites:
		if !is_instance_valid(i): continue
		var og_val = i.sprite_data.duplicate()
		i.sprite_data.mouse_follow = id as FollowMouse
		i.save_state(Global.current_state)
		undo_redo_data.append({sprite_object = i, 
		data = i.sprite_data.duplicate(), 
		og_data = og_val,
		data_type = "sprite_data", 
		state = Global.current_state})
	
	UndoRedoManager.add_data_to_manager(undo_redo_data)
