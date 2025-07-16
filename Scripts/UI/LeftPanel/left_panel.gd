extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	%LayersViewSplit.split_offset = Settings.theme_settings.layers


func _on_layers_view_split_dragged(offset: int) -> void:
	Settings.theme_settings.layers = offset
	Settings.save()
