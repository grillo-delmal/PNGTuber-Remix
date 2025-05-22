extends Control


func _ready() -> void:
	%HSplitContainer.dragged.connect(Themes._on_h_split_container_dragged)
	%HSplit.dragged.connect(Themes._on_h_split_dragged)
	%VSplitContainer.dragged.connect(Themes._on_v_split_container_dragged)




func set_values():
	%HSplitContainer.split_offset = Themes.theme_settings.left
	%HSplit.split_offset = Themes.theme_settings.right
	%VSplitContainer.split_offset = Themes.theme_settings.properties
