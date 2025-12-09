extends Node

var max_health = 100
var health = 100
var frags = 0
var Power = 25
var Level = 1
var max_frags = 10
var stop = false
var encounters = 0
var dialog_count: int = 0
var deaths = 0
var EnemyKilled = []
var EnergyCollected = []
var checkpoint = ""
var Intro = false
var Level1IntroShown := false
var just_reloaded = false


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

func safe_frame() -> void:
	while get_tree() == null:
		await Engine.get_main_loop().process_frame
	await get_tree().process_frame
