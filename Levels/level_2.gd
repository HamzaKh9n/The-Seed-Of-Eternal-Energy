extends Node2D

var paused := false
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

	input_paused = true
	Engine.time_scale = 1.4
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


# ======================================================
#               LEVEL 2 DEATH HANDLER
# ======================================================
func handle_player_death() -> void:
	Global.stop = true
	Global.health = 100
	Global.frags = max(Global.frags - 3, 0)
	Global.EnergyCollected.clear()
	Global.EnemyKilled.clear()

	# INCREASE DEATH COUNT
	Global.deaths += 1
	SaveGame.data.Deaths = Global.deaths
	await SaveGame.save_game()

	# --- WARNINGS BASED ON DEATHS ---
	if Global.deaths == 1:
		await $DialogBox.enqueue("Be careful... You only get a few chances in this level.")
	elif Global.deaths == 3:
		await $DialogBox.enqueue("Warning! You're running out of chances...")
	elif Global.deaths == 4:
		await $DialogBox.enqueue("FINAL WARNING! One more death and the game will RESET!")

	# --- GAME RESETS AFTER 5 DEATHS ---
	if Global.deaths >= 5:
		await $DialogBox.enqueue("You died too many times! The game will now reset.")
		await get_tree().create_timer(2.0).timeout

		SaveGame.reset_save()   # Completely reset game data
		get_tree().change_scene_to_file("res://Title/title.tscn")
		return

	# --- NORMAL LEVEL RELOAD (DEATHS < 5) ---
	await $DialogBox.enqueue("You have fallen! The level will restart.")

	await get_tree().create_timer(2.0).timeout

	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 2.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(1.0).timeout

	$DialogBox.stop_all()

	Global.just_reloaded = true
	get_tree().reload_current_scene()

	Global.stop = false
