extends CanvasLayer

@onready var label: RichTextLabel = $HBoxContainer/VBoxContainer/RichTextLabel
@onready var type_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var full_text := ""
var current_text := ""
var typing := false
var char_speed := 0.02  # time between letters
var dialog_open = false


func show_dialog(text_to_show: String) -> void:
	await wait_until_dialog_free()
	get_tree().get_first_node_in_group("player").anim.play("Idle")
	if get_tree().get_first_node_in_group("player").anim.current_animation == "Idle":
		Global.stop = true
		full_text = text_to_show
		current_text = ""
		typing = true
		dialog_open = true
	

		label.bbcode_enabled = true
		label.text = ""              # start empty
		visible = true               # show dialog UI

		type_text()                 # start typing coroutine


func type_text() -> void:
	for i in full_text.length():
		if not typing:
			break   # instantly skip to full text

		current_text += full_text[i]
		label.text = current_text

		if not type_sound.playing:
			type_sound.play()

		await get_tree().create_timer(char_speed).timeout

	# finish
	label.text = full_text
	typing = false


# Skip text on SPACE
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # SPACE or ENTER
		if typing:
			typing = false   # stops the coroutine, text finishes instantly
		else:
			hide_dialog()    # close when finished
			

func wait_until_dialog_free() -> void:
	while dialog_open:
		await get_tree().process_frame

func hide_dialog() -> void:
	get_tree().paused = false
	dialog_open = false
	visible = false
