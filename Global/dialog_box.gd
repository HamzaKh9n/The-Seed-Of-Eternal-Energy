extends CanvasLayer

@onready var label: RichTextLabel = $HBoxContainer/VBoxContainer/RichTextLabel
@onready var type_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var char_speed: float = 0.02

var _queue: Array = []
var _running := false
var _skip := false
var _typing := false

# ----------------------------------------------------
# PUBLIC: Call this from anywhere
# Example: await $DialogBox.enqueue("Hello there!")
# ----------------------------------------------------
func enqueue(text: String) -> void:
	_queue.append(text)
	if not _running:
		_process_queue()

# ----------------------------------------------------
# PROCESS QUEUE (async)
# ----------------------------------------------------
func _process_queue() -> void:
	_running = true

	while _queue.size() > 0:
		var next_text = _queue.pop_front()

		# Start dialog state
		Global.dialog_count += 1
		Global.stop = true   # ALWAYS freeze when any dialog is running

		await _show_and_type(next_text)

		# End dialog state
		Global.dialog_count = max(Global.dialog_count - 1, 0)
		Global.stop = Global.dialog_count > 0

	_running = false


# ----------------------------------------------------
# SHOW + TYPE COROUTINE
# ----------------------------------------------------
func _show_and_type(text: String) -> void:
	visible = true
	_skip = false
	_typing = true

	label.clear()
	label.bbcode_enabled = true
	label.bbcode_text = text
	label.visible_characters = 0.0

	var total := label.get_total_character_count()
	var current := 0

	while current < total:
		if _skip:
			break

		current += 1
		label.visible_characters = current

		if type_sound and not type_sound.playing:
			type_sound.play()

		await get_tree().create_timer(char_speed).timeout

	# Finish instantly
	label.visible_characters = -1 
	_typing = false

	# Wait for SPACE to close
	while not _skip:
		await get_tree().process_frame

	# Close dialog
	visible = false
	_skip = false
	return


# ----------------------------------------------------
# INPUT: Skip OR Close
# ----------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept"):
		_skip = true    # Skip OR close
