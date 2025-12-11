extends Node2D

@onready var music := $TitleMusic

func _ready():
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print(music)
	music.play()
	SaveGame.load_game()
	
	Global.Level = SaveGame.data.level
	Global.frags = SaveGame.data.frags
	Global.deaths = SaveGame.data.deaths
	Global.upgrades = SaveGame.data.upgrades
	print(Global.Level)
	print(Global.deaths)
	print(Global.frags)
	print(Global.upgrades)
	
	
func _process(_delta):
	if not music.playing:
		music.play()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_play_pressed() -> void:
	await SaveGame.load_game()
	get_tree().change_scene_to_file("res://Levels/level_2.tscn")
	#if Global.Level == 0:
		#get_tree().change_scene_to_file("res://Global/intro.tscn")
	#elif Global.Level == 1:
		#get_tree().change_scene_to_file("res://Levels/level_1.tscn")
	#elif Global.Level == 2:
		#get_tree().change_scene_to_file("res://Levels/level_2.tscn")
