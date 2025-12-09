extends Node2D

@onready var boxes = [$CanvasLayer/VBoxContainer , $CanvasLayer/VBoxContainer2 , $CanvasLayer/VBoxContainer3]
var shown = 0
var start = false

func _ready() -> void:
	$Start.start()
	for box in boxes:
		for text in box.get_children():
			text.modulate.a = 0
	

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		shown = 12
	if shown >= 12:
		SaveGame.data.Intro = true
		SaveGame.save_game()
		get_tree().change_scene_to_file("res://Levels/level_1.tscn")


func fade_in_label(label: RichTextLabel, duration := 4.0):
	label.modulate.a = 0
	var t := 0.0
	while t < duration:
		t += get_process_delta_time()
		label.modulate.a = t / duration
		await get_tree().process_frame
	label.modulate.a = 1
	shown += 1


func fade_out_container(vbox, duration := 4.0):
	var t := 0.0
	while t < duration:
		t += get_process_delta_time()
		vbox.modulate.a = 1.0 - (t / duration)
		await get_tree().process_frame
	vbox.visible = false
	vbox.modulate = Color(1,1,1,1)


func _on_start_timeout() -> void:
	$AudioStreamPlayer2D.play()
	for box in boxes:
		print(box)
		for text in box.get_children():
			await fade_in_label(text)
		if shown%4 == 0:
			await fade_out_container(box)
