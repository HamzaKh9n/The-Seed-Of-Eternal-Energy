extends Node2D

var paused := false
var dialog_shown = false
var encounter_dialog_shown = false
var portal_dialog_shown = false
var portal_interactions = 0
@onready var fade_rect: ColorRect = $FadeIn/ColorRect
var input_paused = false


func _ready() -> void:
	SaveGame.load_game()

	Global.Level = SaveGame.data.level
	Global.frags = SaveGame.data.frags
	Global.health = SaveGame.data.player_health
	Global.checkpoint = SaveGame.data.checkpoint
	Global.deaths = SaveGame.data.Deaths
	Global.EnergyCollected = SaveGame.data.EnergyTaken
	Global.EnemyKilled = SaveGame.data.EnemyKilled
	Global.Intro = SaveGame.data.Intro
	
	input_paused = true
	Engine.time_scale = 1.2
	fade_rect.modulate.a = 1.0  # fully opaque
	fade_in()
	
	
func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 4.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)


func _process(_delta: float) -> void:
	if input_paused:
		if fade_rect.modulate.a == 0:
			Global.stop = false
			input_paused = false
			await $DialogBox.enqueue("Welcome To Level 1")
			await $DialogBox.enqueue("Collect All Energy Fragments and Find the Exit to move on Next Level")
	# ENCOUNTER DIALOG
	if Global.encounters == 1 and not encounter_dialog_shown:
		encounter_dialog_shown = true
		await $DialogBox.enqueue("The Enemies also drop Energy Fragments. Slay them if you can't find enough.")


func fade_out_and_change_scene(path: String) -> void:
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate:a", 1.0, 3.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		SaveGame.save_game()
		get_tree().change_scene_to_file(path)
	)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	elif input_paused:
		Global.stop = true
		get_viewport().set_input_as_handled()
	

func toggle_pause():
	paused = !paused
	get_tree().paused = paused
	$"Pause menu".visible = paused


func _on_resume_pressed() -> void:
	print("resume")
	toggle_pause()


func _on_quit_pressed() -> void:
	toggle_pause()
	SaveGame.save_game()
	get_tree().change_scene_to_file("res://Title/title.tscn")


func _on_tp_area_entered(area: Area2D) -> void:
	if area.is_in_group('PlayerHitbox'):
		if Global.frags >= 10:
			await $DialogBox.enqueue("Congratulations !! You Found the Portal.")
			Global.stop = false
			fade_out_and_change_scene("res://Levels/level_2.tscn")
		else:
			if portal_interactions >= 1:
				await $DialogBox.enqueue("Not Enough Energy Fragments")
			else:
				await $DialogBox.enqueue("Congratulations !! You Found the Portal || Collect Enough Energy frags to Pass Through It.")
		portal_interactions += 1
