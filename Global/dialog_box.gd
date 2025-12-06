extends CanvasLayer

@onready var label: RichTextLabel = $HBoxContainer/VBoxContainer/RichTextLabel
@onready var type_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var char_speed: float = 0.02

var _queue: Array = []
var _running := false
var _skip := false
var _typing := false
var _current_non_skippable := false

# ----------------------------------------------------
# PUBLIC: Call this from anywhere
# Example: await $DialogBox.enqueue("Hello there!")  OR
#          await $DialogBox.enqueue("You died!", true)  (non-skippable)
# ----------------------------------------------------
func enqueue(text, non_skippable := false) -> void:
	# push a dictionary so we can pass the non_skippable flag
	_queue.append({"text": text, "non_skippable": non_skippable})
	if not _running:
		_process_queue()

# Stop all typing and clear the queue safely (call before reload)
func stop_all() -> void:
	_queue.clear()
	_skip = true
	_current_non_skippable = false
	_typing = false
	_running = false
	visible = false

# ----------------------------------------------------
# PROCESS QUEUE (async)
# ----------------------------------------------------
func _process_queue() -> void:
	_running = true

	while _queue.size() > 0:
		var entry = _queue.pop_front()
		var next_text = entry.get("text")
		var non_skip = entry.get("non_skippable", false)

		# Start dialog state
		Global.dialog_count += 1
		Global.stop = true   # ALWAYS freeze when any dialog is running

		await _show_and_type(next_text, non_skip)

		# End dialog state
		Global.dialog_count = max(Global.dialog_count - 1, 0)
		Global.stop = Global.dialog_count > 0

	_running = false

# ----------------------------------------------------
# SHOW + TYPE COROUTINE
# ----------------------------------------------------
func _show_and_type(text: String, non_skippable := false) -> void:
	visible = true
	_skip = false
	_typing = true
	_current_non_skippable = non_skippable

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

		# safe short wait
		# using create_timer is OK here; it will be cancelled if scene is reloaded
		await get_tree().create_timer(char_speed, false).timeout

	# Finish instantly
	label.visible_characters = -1 
	_typing = false

	# Wait for SPACE to close UNLESS non_skippable is true
	if non_skippable:
		# For non-skippable messages we still want to wait for at least one input
		# but ignore skipping attempts. We'll wait until an explicit close call (skip flag set by code)
		# So we block here until _skip becomes true (set by caller via stop_all, or after a timer).
		# To avoid tight loop or null errors on reload, poll with small timers.
		while not _skip:
			if get_tree() == null:
				break
			await get_tree().create_timer(0.05, false).timeout
	else:
		while not _skip:
			if get_tree() == null:
				break
			await get_tree().create_timer(0.05, false).timeout

	# Close dialog
	visible = false
	_skip = false
	_current_non_skippable = false
	return

# ----------------------------------------------------
# INPUT: Skip OR Close
# ----------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# If current dialog is non-skippable, ignore ui_accept here
	if _current_non_skippable:
		return

	if event.is_action_pressed("ui_accept"):
		_skip = true    # Skip OR close
