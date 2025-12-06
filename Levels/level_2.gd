extends Node2D

var paused := false
var dialog_shown = false
var encounter_dialog_shown = false
var portal_dialog_shown = false
var portal_interactions = 0
@onready var fade_rect: ColorRect = $FadeIn/ColorRect
var input_paused = false

# ----- NEW VARIABLES -----
var death_counter := 0
var level_start_position := Vector2.ZERO
var first_death_warning_shown := false

func _ready() -> void:
	# Load Save Game
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
	
	# Fade-in setup
	fade_rect.modulate.a = 1.0
	fade_in()

	# Store level start position
	var player = get_node("../Player")  # adjust path to your Player node
	level_start_position = player.global_position

	# Reset death counter on level start
	death_counter = 0

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
			await $DialogBox.enqueue("Welcome To Level 2")

# ----- PLAYER DEATH HANDLING -----
func handle_player_death() -> void:
	var player = get_node("../Player")  # adjust path to your Player node
	death_counter += 1

	# Subtract 2 frags each death
	Global.frags -= 2
	if Global.frags < 0:
		Global.frags = 0

	# Clear collected energy and enemies
	Global.EnergyCollected.clear()
	Global.EnemyKilled.clear()

	# First death warning dialog
	if death_counter == 1 and not first_death_warning_shown:
		first_death_warning_shown = true
		await $DialogBox.enqueue("If you die 4 more times, the game will reset. Every death costs 2 Energy Fragments.")

	# Show remaining deaths warning
	if death_counter < 5:
		var remaining = 5 - death_counter
		await $DialogBox.enqueue("If you die %d more time%s, the game will reset." % [remaining, "s" if remaining > 1 else ""])

		player.global_position = level_start_position
		Global.health = 100
		return

	# On fifth death, reset game
	if death_counter >= 5:
		await $DialogBox.enqueue("You died 5 times. Game will reset.")
		SaveGame.reset_game()
		get_tree().change_scene_to_file("res://Title/title.tscn")

func _on_tp_area_entered(area: Area2D) -> void:
	if area.is_in_group('PlayerHitbox'):
		if Global.frags >= 10:
			await $DialogBox.enqueue("Congratulations !! You Found the Portal.")
			Global.stop = false
			fade_out_and_change_scene("res://Levels/level_3.tscn")
		else:
			if portal_interactions >= 1:
				await $DialogBox.enqueue("Not Enough Energy Fragments")
			else:
				await $DialogBox.enqueue("Congratulations !! You Found the Portal || Collect Enough Energy Frags to Pass Through It.")
		portal_interactions += 1

func fade_out_and_change_scene(path: String) -> void:
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate:a", 1.0, 3.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
	)
