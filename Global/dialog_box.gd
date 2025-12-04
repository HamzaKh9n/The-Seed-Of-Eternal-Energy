extends CanvasLayer

@onready var panel = $Panel
@onready var label = $Panel/Label
@onready var type_timer = $Panel/Timer

var full_text := ""
var current_char := 0
var typing := false
var finished := false

func show_dialog(text: String):
	full_text = text
	label.text = ""
	current_char = 0
	typing = true
	finished = false
	panel.visible = true
	type_timer.start()

func _on_Timer_timeout():
	if typing:
		if current_char < full_text.length():
			label.text += full_text[current_char]
			current_char += 1
		else:
			typing = false
			finished = true
			type_timer.stop()

func _input(event):
	if not panel.visible:
		return

	# Skip typing
	if event.is_action_pressed("ui_accept"):
		if typing:
			label.text = full_text
			typing = false
			finished = true
			type_timer.stop()
		elif finished:
			panel.visible = false
