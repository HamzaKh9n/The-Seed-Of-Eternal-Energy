extends Node2D

@export var startposition : float
@export var cameraposition : float
@export var fightposition : float
@onready var fade_rect: ColorRect = $FadeIn/ColorRect
var input_paused = false
var paused := false
var cutscene_running := false

func _ready() -> void:
	$MC/CROSSROADS.play()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SaveGame.load_game()
	input_paused = false
	Global.unlock_input()
	Global.stop = false
	Global.fight_started = false
	Global.upgrades = SaveGame.data.upgrades
	#Global.max_frags = 25
	#Global.frags = 10
	Global.health = 100
	Global.deaths = 0
	Global.Level = 3
	print("Level" , Global.Level)
	SaveGame.save_game()

	#input_paused = true
	#Engine.time_scale = 1.4
	fade_rect.modulate.a = 1.0
	fade_in()
	await $DialogBox.enqueue("Welcome to Level 3!!")
	if Global.just_reloaded:
		input_paused = false
		Global.stop = false
		Global.just_reloaded = false

func startmusic():
	$MC/CROSSROADS.stop()
	if not $MC/BossFight.playing:
		$MC/BossFight.play()	

func _process(delta: float) -> void:

	# Prevent re-triggering while cutscene is running
	if cutscene_running:
		return

	if $MC.global_position.x >= startposition and not Global.fight_started:

		cutscene_running = true   # IMPORTANT

		Global.lock_input()

		# Smooth move camera to target

		await tween_camera_x(cameraposition)
		# Apply limits AFTER tween completes
		$MC/Camera2D.limit_left = 2300
		$MC/Camera2D.limit_right = 3750

		# Start auto-walk cutscens
		# Wait until the player reaches the fight position
		await _wait_until_mc_reaches(fightposition)

		# Cutscene ends
		$MC.stop_cutscene_1()
		print("Cutscene Stopped")
		Global.unlock_input()
		Global.fight_started = true
		Global.stop = false
		startmusic()
		cutscene_running = false   # Cutscene completely finished
		$StaticBody2D/CollisionShape2D.disabled = false
		$StaticBody2D/CollisionShape2D2.disabled = false

func _wait_until_mc_reaches(x: float) -> void:
	while $MC.global_position.x < x:
		$MC.play_cutscene_1()
		#print($MC.global_position.x)
		await Global.safe_frame()   # replaced process_frame

func tween_camera_x(target_x: float, duration := 1.0):
	var cam := $MC/Camera2D
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		func(v): cam.global_position.x = v,
		cam.global_position.x,
		target_x,
		duration
	)

	await tween.finished   # waits correctly

func _on_rest_spot_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyHitbox"):
		$ReaperBoss.attack_type = ''
		#$ReaperBoss.flip_reaper(-1)

func _on_rest_spot_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyHitbox"):
		$ReaperBoss.attack_type = ''
		#$ReaperBoss.flip_reaper(1)

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 4.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

func fade_out_and_change_scene(path: String) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 3.0)
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
		#$MC/CROSSROADS.stream_paused = true
		
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#$MC/CROSSROADS.stream_paused = false

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_quit_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://Title/title.tscn")


func _on_boss_fight_finished() -> void:
	$MC/BossFight.play()
