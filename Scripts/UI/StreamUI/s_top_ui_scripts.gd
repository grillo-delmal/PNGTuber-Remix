extends Node


func _on_file_button_pressed() -> void:
	SaveAndLoad.load_file("res://DemoModels/PickleModel.pngRemix")
	await get_tree().create_timer(0.1).timeout
