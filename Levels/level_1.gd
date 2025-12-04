extends Node2D


var paused := false

func _ready() -> void:
	Global.Level = 1
	Global.max_frags = 10
	Global.frags = 10


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	paused = !paused
	get_tree().paused = paused

	$"Pause menu".visible = paused


	
func _on_resume_pressed() -> void:
	print("resume")
	toggle_pause()


#
func _on_quit_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://Title/title.tscn")


func _on_tp_area_entered(area: Area2D) -> void:
	if area.is_in_group('PlayerHitbox'):
		if Global.frags >= 10:
			get_tree().change_scene_to_file("res://Levels/level_2.tscn")
		else:
			print("Not Enough Frags")
