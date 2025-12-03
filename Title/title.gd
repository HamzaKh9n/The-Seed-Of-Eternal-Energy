extends Node2D

@onready var music := $TitleMusic

func _ready():
	print(music)
	music.play()

func _process(_delta):
	if not music.playing:
		music.play()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Emperor's Grave Scenes/graves.tscn")
