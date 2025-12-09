extends CanvasLayer


var paused = false
	
func _on_resume_pressed() -> void:
	print("resume")
	toggle_pause()


func toggle_pause():
	paused = !paused
	get_tree().paused = paused

	$"Pause menu".visible = paused
#
func _on_quit_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://Title/title.tscn")
	SaveGame.save_game()
