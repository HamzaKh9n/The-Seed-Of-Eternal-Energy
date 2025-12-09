extends Node2D

var paused := false
var encounter_dialog_shown = false
var portal_dialog_shown = false
var portal_interactions = 0
@onready var fade_rect: ColorRect = $FadeIn/ColorRect
var input_paused = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SaveGame.load_game()

	Global.Level = SaveGame.data.level
	Global.frags = SaveGame.data.frags
	Global.health = SaveGame.data.player_health
	Global.checkpoint = SaveGame.data.checkpoint
	Global.deaths = SaveGame.data.Deaths
	Global.EnergyCollected = SaveGame.data.EnergyTaken
	Global.EnemyKilled = SaveGame.data.EnemyKilled

	# ONLY RESET INTRO SHOWN WHEN COMING FROM TITLE
	# NOTE: SaveGame resets this automatically on Title.

	input_paused = true
	Engine.time_scale = 1.2
	fade_rect.modulate.a = 1.0
	fade_in()
	if Global.just_reloaded:
		input_paused = false
		Global.stop = false
		Global.just_reloaded = false

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 4.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

func _process(_delta: float) -> void:

	# ---------------------------
	# SHOW INTRO ONLY ONE TIME
	# ---------------------------
	if input_paused and not Global.Level1IntroShown:
		if fade_rect.modulate.a == 0:
			input_paused = false
			Global.stop = false

			Global.Level1IntroShown = true  # <-- NEVER SHOW AGAIN in this run
			await $DialogBox.enqueue("Welcome To Level 1")
			await $DialogBox.enqueue("Collect All Energy Fragments and Find the Exit to move on Next Level")

	# ENCOUNTER DIALOG
	if SaveGame.data.Deaths < 1:
		if Global.encounters == 1 and not encounter_dialog_shown:
			encounter_dialog_shown = true
			await $DialogBox.enqueue("The Enemies also drop Energy Fragments. Slay them if you can't find enough.")

	# CHECK PLAYER DEATH
	if Global.health <= 0:
		await handle_player_death()


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
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$MC/CROSSROADS.stream_paused = true
		
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		$MC/CROSSROADS.stream_paused = false

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_quit_pressed() -> void:
	toggle_pause()
	SaveGame.save_game()
	get_tree().change_scene_to_file("res://Title/title.tscn")

func _on_tp_area_entered(area: Area2D) -> void:
	if area.is_in_group('PlayerHitbox'):
		if Global.frags >= 10:
			await $DialogBox.enqueue("Congratulations !! You Found the Portal.")
			fade_out_and_change_scene("res://Levels/level_2.tscn")
		else:
			if portal_interactions >= 1:
				await $DialogBox.enqueue("Not Enough Energy Fragments")
			else:
				await $DialogBox.enqueue("Congratulations !! You Found the Portal || Collect Enough Energy frags to Pass Through It.")
		portal_interactions += 1

# ---------------------------------
# PLAYER DEATH HANDLER (LEVEL 1)
# ---------------------------------
func handle_player_death() -> void:
	Global.stop = true
	Global.health = 100
	Global.frags = max(Global.frags - 2, 0)
	Global.EnergyCollected.clear()
	Global.EnemyKilled.clear()

	# prevent encounter dialog from re-showing after reload
	Global.encounters = 0

	# Show an UN-SKIPPABLE death message
	await $DialogBox.enqueue("You have fallen! The level will restart. Be careful next time.", true)

	# delay before fade
	await get_tree().create_timer(2.0).timeout

	# fade out
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 2.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(1.0).timeout

	# IMPORTANT: STOP CURRENT DIALOGS SAFELY BEFORE RELOAD
	$DialogBox.stop_all()

	# reload scene
	Global.deaths += 1
	SaveGame.data.Deaths = Global.deaths
	Global.just_reloaded = true   # if you use this flag elsewhere
	await SaveGame.save_game()
	get_tree().reload_current_scene()

	Global.stop = false
