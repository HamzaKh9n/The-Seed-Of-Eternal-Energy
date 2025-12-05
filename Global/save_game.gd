extends Node

const SAVE_PATH := "user://savegame.json"

var data := {
	"level" : 1,
	"frags" : 0,
	"player_health" : 100,
	"checkpoint" : 1,
	"Deaths" : 0,
	"EnergyTaken":[],
	"EnemyKilled":[]
}

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("Game Saved -> ", SAVE_PATH)


func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save found, creating new...")
		save_game()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var loaded_data = JSON.parse_string(content)
	if loaded_data:
		data = loaded_data
		print("Game Loaded")
	else:
		print("Error loading save (corrupted file). Resetting...")
		save_game()


func reset_game():
	data = {
		"level" : 1,
		"frags" : 0,
		"player_health" : 100,
		"checkpoint" : 1,
		"Deaths" : 0,
		"EnergyTaken":[],
		"EnemyKilled":[]
	}
	save_game()
