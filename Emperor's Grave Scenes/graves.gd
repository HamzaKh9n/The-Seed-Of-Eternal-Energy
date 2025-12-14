extends Node2D


var paused := false
@onready var fade_rect: ColorRect = $FadeIn/ColorRect

func _ready() -> void:
	Global.Level = 5
	fade_in()

func _process(delta: float) -> void:
	if $MC.global_position.x >= 16000:
		fade_out_and_change_scene('res://Levels/ending_scene.tscn')

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 4.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	Global.stop = false


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	paused = !paused
	get_tree().paused = paused

	$"Pause menu".visible = paused


func fade_out_and_change_scene(path: String) -> void:
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate:a", 1.0, 3.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		SaveGame.save_game()
		get_tree().change_scene_to_file(path)
	)

	
func _on_resume_pressed() -> void:
	print("resume")
	toggle_pause()


#
func _on_quit_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://Title/title.tscn")
