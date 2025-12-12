extends Node

var input_locked := false

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

#Boss Fghts
var fight_started = false


var saved_actions := {}    # stores original action states


func lock_input() -> void:
	if input_locked:
		return
	input_locked = true
	stop = true

	# Disable every single action except ESC
	saved_actions.clear()
	for action_name in InputMap.get_actions():
		if action_name == "ui_cancel":
			continue
		saved_actions[action_name] = InputMap.action_get_events(action_name).duplicate()
		InputMap.action_erase_events(action_name)
	


func unlock_input() -> void:
	if not input_locked:
		return
	input_locked = false
	stop = false
	# Restore input actions
	for action_name in saved_actions.keys():
		for ev in saved_actions[action_name]:
			InputMap.action_add_event(action_name, ev)
	_reset_stuck_inputs()

	saved_actions.clear()

func _reset_stuck_inputs():
	# Release all movement and action states manually
	Input.action_release("A")
	Input.action_release("D")
	Input.action_release("Space")
	Input.action_release("Attack")
	Input.action_release("Dash")



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
		
	if not input_locked:
		return

	# If locked, ALLOW ONLY ESC
	if event.is_action_pressed("ui_cancel"):
		return  # Pass through normally

	# Block everything else
	#print('Locked input')
	get_viewport().set_input_as_handled()

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
