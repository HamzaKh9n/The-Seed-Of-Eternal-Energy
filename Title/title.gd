extends Node2D

@onready var music := $TitleMusic

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print(music)
	music.play()
	SaveGame.load_game()
	Global.Level = SaveGame.data.level
	Global.frags = SaveGame.data.frags
	Global.health = SaveGame.data.player_health
	Global.checkpoint = SaveGame.data.checkpoint
	Global.deaths = SaveGame.data.Deaths
	Global.EnergyCollected = SaveGame.data.EnergyTaken
	Global.EnemyKilled = SaveGame.data.EnemyKilled
	Global.Intro = SaveGame.data.Intro

func _process(_delta):
	if not music.playing:
		music.play()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_play_pressed() -> void:
	await SaveGame.load_game()
	#if not Global.Intro:
		#get_tree().change_scene_to_file('res://Global/intro.tscn')
	#else:
		#if Global.Level == 1:
			#get_tree().change_scene_to_file("res://Levels/level_1.tscn")
		#elif Global.Level == 2:
			#get_tree().change_scene_to_file("res://Levels/level_2.tscn")
		#elif Global.Level == 3:
			#get_tree().change_scene_to_file("res://Levels/level_3.tscn")
		#elif Global.Level == 0:
			#get_tree().change_scene_to_file("res://Emperor's Grave Scenes/graves.tscn")
	get_tree().change_scene_to_file("res://Levels/level_1.tscn")
