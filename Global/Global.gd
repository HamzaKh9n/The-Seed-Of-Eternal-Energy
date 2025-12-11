extends Node

var max_health = 100
var health = 100
var frags = 0
var Power = 25
var Level = 0
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

# Upgrades and Powerups
var upgrades = []
var upgrade = null
var knockback = false
var stun = false
var dash = true
var ragemode = false
var lifesteal = false
var damage = false
var heal = false



var upgrade1 = false

@onready var upgrade_scene = preload("res://Global/upgrades.tscn")
@onready var messagebox = preload("res://Global/messages.tscn")
var message = null

func _ready() -> void:
	for x in Global.upgrades:
		match x:
			"knockback":
				knockback = true
			"stun":
				stun = true
			"dash":
				dash = true
			"lifesteal":
				lifesteal = true
			"ragemode":
				ragemode = true
			"damage":
				damage = true
				Global.Power = 34
			"heal":
				heal = true



func _process(_delta: float) -> void:
	if upgrade != null:
		upgrades.append(upgrade)
		give_powerup(upgrade)
		upgrade = null
		message = messagebox.instantiate()
		add_child(message)
		message.show_message("Powered Up...." ,1 , true)
	
	#if Global.frags == 5 and not upgrade1:
		#upgrade1 = true
		#get_tree().get_first_node_in_group("upgrades").create_upgrades(["Healing" , "Heal 20% Health with Energies" , "heal"] , ["Damage" , "Increase Damage" , "damage"] , ["Knockback" , "" , "knockback"])
	

func give_powerup(x):
	match x:
		"knockback":
			knockback = true
		"stun":
			stun = true
		"dash":
			dash = true
		"lifesteal":
			lifesteal = true
		"ragemode":
			ragemode = true
		"damage":
			damage = true
			Global.Power = 34
		"heal":
			heal = true
	print("Upgraded" , x )
	stop = false
	#message.hide_message()

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
