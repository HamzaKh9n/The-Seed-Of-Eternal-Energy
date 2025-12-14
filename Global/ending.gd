extends Node2D

@onready var boxes = [
	$CanvasLayer/VBoxContainer,
	$CanvasLayer/VBoxContainer2,
	$CanvasLayer/VBoxContainer3
]

@onready var messageBox = preload("res://Global/messages.tscn")
@onready var fade_rect = $FadeIn/ColorRect
@onready var creditScene = preload("res://Global/credits.tscn")
var first_skip_used := false
var shown := 0
var credits_running := false
var credits_instance = null   # 


func _ready() -> void:
	#Engine.time_scale = 5
	$Start.start()
	fade_rect.modulate.a = 0

	# hide intro text initially
	for box in boxes:
		for text in box.get_children():
			text.modulate.a = 0


func _process(_delta: float) -> void:

	# --- SPACE SKIP HANDLING ---
	if Input.is_action_just_pressed("ui_accept"):

		if not credits_running and not first_skip_used:
			first_skip_used = true
			shown = 12   # force intro completion
			return
			
		if credits_running and first_skip_used:
			print('skipped')
			if credits_instance:
				credits_instance.stop_credits()
			get_tree().change_scene_to_file("res://Global/game_title.tscn")
			return
			
	# --- When intro text is finished → start credits ---
	if shown >= 12 and not credits_running:
		await Global.safe_frame()
		print('started credits')
		_start_credits()



# ------------------------------------------------------------
# START CREDITS
# ------------------------------------------------------------
func _start_credits():
	credits_running = true

	credits_instance = creditScene.instantiate()
	get_parent().add_child(credits_instance)

	# Make sure credits appear on top (CanvasLayer)
	if credits_instance.has_method("set_layer"):
		credits_instance.set_layer(10)

	$CanvasLayer.visible = false



# ------------------------------------------------------------
# TEXT FADE-IN
# ------------------------------------------------------------
func fade_in_label(label: RichTextLabel, duration := 4.0):
	if credits_running:
		return  # stop intro if credits started

	label.modulate.a = 0
	var t := 0.0

	while t < duration:
		t += get_process_delta_time()
		label.modulate.a = t / duration
		await get_tree().process_frame

	label.modulate.a = 1
	shown += 1

	# show the "Press Space to skip" box
	if shown == 2:
		var message = messageBox.instantiate()
		$CanvasLayer.add_child(message)
		message.show_message("Press Space To Skip", 4)



# ------------------------------------------------------------
# FADE OUT ENTIRE BOX
# ------------------------------------------------------------
func fade_out_container(vbox, duration := 4.0):
	if credits_running:
		return

	var t := 0.0
	while t < duration:
		t += get_process_delta_time()
		vbox.modulate.a = 1.0 - (t / duration)
		await get_tree().process_frame

	vbox.visible = false
	vbox.modulate = Color(1,1,1,1)



# ------------------------------------------------------------
# INTRO SEQUENCE
# ------------------------------------------------------------
func _on_start_timeout() -> void:
	$AudioStreamPlayer2D.play()

	for box in boxes:
		for text in box.get_children():
			await fade_in_label(text)

		if shown % 4 == 0:
			await fade_out_container(box)



# ------------------------------------------------------------
# OPTIONAL FADE FUNCTION
# ------------------------------------------------------------
func fade_out_and_change_scene(path: String) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect , "modulate:a", 1.0, 3.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	SaveGame.save_game()
	get_tree().change_scene_to_file(path)
