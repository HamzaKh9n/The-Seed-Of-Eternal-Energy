extends Node2D

@export var startposition : float
@export var cameraposition : float
@export var fightposition : float

var cutscene_running := false


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
