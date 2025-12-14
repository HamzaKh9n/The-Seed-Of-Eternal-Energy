extends Node2D

@onready var fade_rect: ColorRect = $FadeIn/ColorRect
var paused = false
@onready var player =  $MC
@onready var dialog = get_tree().get_first_node_in_group('DialogBox')
var cutscene1 =  false
var cutscene2 = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.lock_input()
	Global.saved_actions = {}
	fade_in()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Engine.time_scale = 2
	if not cutscene1:
		cutscene1 = true
		print('playing cutscene')
		await wait_player(800)
		player.anim.play('Idle')
		player.stop_cutscene_2()
		play_fake_ending()

func wait_player(position):
	while player.global_position.x < position:
		player.play_cutscene_2()
		await Global.safe_frame()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	paused = !paused
	get_tree().paused = paused
	$"Pause menu".visible = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$MC/AudioStreamPlayer2D.stream_paused = true
		
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		$MC/AudioStreamPlayer2D.stream_paused = false



	
func _on_resume_pressed() -> void:
	print("resume")	
	toggle_pause()


#
func _on_quit_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://Title/title.tscn")


func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 4.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	Global.stop = false


func play_fake_ending() -> void:

	await dialog.enqueue("You found it.", true)
	await short_pause()
	
	await dialog.enqueue("The Seed of Eternal Energy.", true)
	await short_pause()
	
	await dialog.enqueue(
		"A promise the world chased for centuries.", true
	)
	await short_pause()

	await dialog.enqueue(
		"Clean. Endless. Silent.", true
	)
	await short_pause()

	await dialog.enqueue(
		"For the first time… the world feels calm.", true
	)
	await short_pause()

	await dialog.enqueue(
		"You did what no one else could.", true
	)
	await short_pause()

	await dialog.enqueue(
		"But energy is not hope.", true
	)
	await short_pause()

	await dialog.enqueue(
		"And hope was never meant to be carried alone.", true
	)
	await get_tree().create_timer(1).timeout
	await short_pause()
	
	# HOLD SILENCE
	await get_tree().create_timer(2.0).timeout
	
	if not cutscene2:
		cutscene2=true
		trigger_reaper_return()

func short_pause():
	await get_tree().create_timer(2).timeout
	dialog.stop_all()


func fade_out_and_change_scene(path: String) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 4.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	SaveGame.save_game()
	get_tree().change_scene_to_file(path)


func trigger_reaper_return():
	dialog.stop_all()          # IMPORTANT
	Global.stop = false        # Allow movement for ONE FRAME
	$MC/AudioStreamPlayer2D.stop()
	# sudden sound / sting here
	#$ReaperAppearSound.play()

	await get_tree().create_timer(0.1).timeout
	await $ReaperBoss.play_custcene()
	Global.health -= 100
	player.anim.stop()
	player.anim.play('Death')
	await player.anim.animation_finished
	print('death anim finished')
	#player.paused = true
	#player.stop_cutscene_2()
	fade_out_and_change_scene('res://Global/ending.tscn')
	await get_tree().create_timer(1).timeout
		
	
	#$Reaper.spawn_and_kill_player()
