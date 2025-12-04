extends Node

var max_health = 100
var health = 10
var frags = 0
var Power = 25
var Level = 1

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		toggle_fullscreen()

func toggle_fullscreen():
	var win_id = get_window().get_window_id()
	var current_mode = DisplayServer.window_get_mode(win_id)

	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, win_id)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, win_id)
