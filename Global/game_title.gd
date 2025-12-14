extends Node2D

@onready var fade_rect: ColorRect = $FadeIn/ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_in()



func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 4.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	Global.stop = false
	await tween.finished
	await get_tree().create_timer(2).timeout
	fade_out_and_change_scene('res://Title/title.tscn')

func fade_out_and_change_scene(path: String) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect , "modulate:a", 1.0, 3.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	#SaveGame.save_game()
	get_tree().change_scene_to_file(path)
