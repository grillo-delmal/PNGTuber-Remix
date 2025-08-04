extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.update_ui_pieces.connect(ui_pieces)
	await get_tree().create_timer(0.1).timeout
	#%LayersViewSplit.split_offset = Settings.theme_settings.layers


func _on_layers_view_split_dragged(offset: int) -> void:
	Settings.theme_settings.layers = offset
	Settings.save()

func ui_pieces():
	%Dockable.layout.set_node_hidden(%CameraPanel, !Settings.theme_settings.hide_mini_view)
	#%CameraPanel.visible = Settings.theme_settings.hide_mini_view
	%Dockable.layout.set_node_hidden(%BG, !Settings.theme_settings.hide_sprite_view)
	#%BG.visible = Settings.theme_settings.hide_sprite_view
