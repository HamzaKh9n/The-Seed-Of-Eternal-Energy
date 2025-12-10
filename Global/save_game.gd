extends Node

const SAVE_PATH := "user://savegame2.json"

var data := {
	"level":Global.Level,
	"frags":Global.frags,
	"deaths":Global.deaths,
	"upgrades":Global.upgrades
}

func save_game():
	
	data = {
		"level":Global.Level,
		"frags":Global.frags,
		"deaths":Global.deaths,
		"upgrades":Global.upgrades
	}
	
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
		for i in data.upgrades:
			print(i)
		print("Game Loaded")
	else:
		print("Error loading save (corrupted file). Resetting...")
		save_game()


func reset_game():
	Global.Level = 0
	Global.frags = 0
	Global.deaths = 0
	Global.upgrades = []
	
	data = {
		"level":Global.Level,
		"frags":Global.frags,
		"deaths":Global.deaths,
		"upgrades":Global.upgrades
	}
	
	save_game()
