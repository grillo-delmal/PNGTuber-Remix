extends Control


func _ready() -> void:
	%HSplitContainer.dragged.connect(Settings._on_h_split_container_dragged)
	%HSplit.dragged.connect(Settings._on_h_split_dragged)
	%VSplitContainer.dragged.connect(Settings._on_v_split_container_dragged)




func set_values():
	%HSplitContainer.split_offset = Settings.theme_settings.left
	%HSplit.split_offset = Settings.theme_settings.right
	%VSplitContainer.split_offset = Settings.theme_settings.properties
