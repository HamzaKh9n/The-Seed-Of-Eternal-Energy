extends CharacterBody2D

@onready var attack_radius = $AttackRadius
@onready var melee_radius = $MeleeRadius
@onready var hitbox = $Hitbox
@onready var summon_point = $SummonPoint
@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var restTIme = $Rest

var damage_flash_running := false

@onready var attack_cooldown = $Attack_Cooldown

@export var move_speed =  150
@onready var summon = preload('res://Characters/summon.tscn')
var distance = null
var direction = null
var attacking = false

#Attack Types
var can_melee = false
var can_summon = false
@onready var summonCooldown = $SummonCooldown
var can_tp = false
@onready var tpCooldown = $TpCooldown
var attack_type = ""
var work_in_progress = false
@export var cutscene = false
var state = "idle"
var stun = false
var returning = false
var canThink = false
var attackReset = false

var in_melee = false
var in_attack = false

var health = 500.0
var max_health = 500.0
var phase = 1
var death_animation_running = false

func _ready() -> void:
	summonCooldown.start()
	tpCooldown.start()
	


func _physics_process(_delta: float) -> void:
	if cutscene:
		return
	if death_animation_running:
		return
		
	if not Global.fight_started:
		change_state("idle")
		return
	
	if health <- 0:
		anim.play('Death')
		return
	
	if stun:
		velocity = Vector2.ZERO
		if not state.begins_with("attack"):
			change_state('idle')
		
	if state == 'idle':
		anim.play('Idle')
	
	if check_checkpoint() != null:
		canThink = true
	else:
		canThink = false
	
	if not canThink:
		tp_back()
		
	check_phase()
	#print(phase)
	in_melee = get_player_in_area(melee_radius)
	in_attack = get_player_in_area(attack_radius)
	#var in_hitbox = get_player_in_area(hitbox)
	
	distance = player.global_position.x - global_position.x
	direction = (player.global_position - global_position).normalized()
	
	if not returning and restTIme.is_stopped():
		###print('jjjjjjjjjjjjjjjjjj')
		velocity.x = 0
		if canThink:
			chose_attack()
		#print(attack_type)
		if in_melee and not work_in_progress and attack_type == '':
			attack_type = 'melee'
		#if prev_type != attack_type:
		##print(attack_type)
		if attack_type == "":
			attack_type = 'tp'
			can_tp = true
		elif attack_type == 'tp' and not work_in_progress and can_tp:
			##print("tpppppppppppppppppppp")
			await tp_attack()
			stun = true
			await get_tree().create_timer(2).timeout
			stun = false
			work_in_progress = false
			attack_type = ''
			
		elif attack_type == 'melee' and not work_in_progress and can_melee and not in_attack:
			###print('chasing')
			work_in_progress = true
			while work_in_progress:
				chase_player()
				await Global.safe_frame()
			
		elif attack_type == 'summon' and not work_in_progress and can_summon:
			work_in_progress = true
			##print('wanna summon')
			var ghost = summon.instantiate()
			#summon_point.add_child(ghost)
			await anim.animation_finished
			while check_checkpoint() == null:
				await Global.safe_frame()
			###print('changed state to summon')
			change_state('summon')
			await anim.animation_finished
			get_parent().add_child(ghost)
			ghost.global_position = summon_point.get_child(0).global_position
			ghost.scale = Vector2(4, 4)
			change_state('idle')
			work_in_progress = false
			attack_type = ''
			##print(anim.current_animation)
		
	if in_attack and not attacking and attack_cooldown.is_stopped() and not returning:
		work_in_progress = false
		var rnum = randi_range(0,1)
		###print("Atttacking" , rnum)
		if rnum == 0:
			if state != 'skill':
				change_state("attack1")
		else:
			if state != 'skill':
				change_state("attack2")
		await anim.animation_finished
		tp_back()
	move_and_slide()


func get_player_in_area(area):
	var areas = area.get_overlapping_areas()
	for i in areas:
		if i.is_in_group("PlayerHitbox"):
			return true
	return false
		

func flip_reaper(x):
	if x > 0:
		sprite.flip_h = false
		attack_radius.position.x = 0
		summon_point.position.x = 0
	elif x <0 :
		sprite.flip_h = true
		attack_radius.position.x = -35	
		summon_point.position.x = -100

func chase_player():
	#var dir = 0
	if returning:
		return
	
	flip_reaper(distance)
		
	if not state.begins_with("attack"):
		change_state("idle")
	if not stun:
		velocity = direction * move_speed
	#change_state("Idle")
	
	move_and_slide()
	
func stop_chasing():
	direction = Vector2.ZERO
	
func change_state(x):
	###print('Changing State' , x)
	
	if not x == state:	
		##print("stopped anim")
		anim.stop()
	var prev = state
	state = x
	
	if state == 'idle' and not prev.begins_with('attack') and prev != 'skill' and prev != 'summon':
		###print('yeahhh Idlee')
		anim.play("Idle")
		attacking = false
	elif state == "attack1":
		anim.play("Attack 1")
		attacking = true
	elif state == "attack2":
		anim.play("Attack 2")
		attacking = true
	elif state == 'death':
		anim.play("Death")
		attacking = false
	elif state == 'summon':
		anim.play("Summon")
		attacking = false
	elif state == "skill":
		anim.play("Skill")
		attacking = false
		
	if state.begins_with("attack"):
		await anim.animation_finished
		attack_cooldown.start()
		change_state("idle")
		##print("Player Got Damaged")
		await attack_cooldown.timeout
		attack_cooldown.stop()
	
func check_phase():
	
	var health_percent = (health/max_health)*100
	#print('Health Percent' , health_percent)
	
	if health_percent >= 75:
		phase = 1 	
		
	elif health_percent >= 35 and health_percent <75:
		phase = 2
		tpCooldown.wait_time = 15
		summonCooldown.wait_time = 15
	elif health_percent<35 and health_percent > 0:
		phase = 3
		tpCooldown.wait_time = 5
		summonCooldown.wait_time = 10
	if health_percent <= 0:
		phase = 4
	
func chose_attack():
	#print(attack_type)
	if not attack_type == '':
		return
	if check_checkpoint() == null:
		tp_back()
		return
	if not restTIme.is_stopped():
		return
	var rnum = randi_range(1 , 100)
	if phase == 1:
		if rnum <= 20 and summonCooldown.is_stopped():
			toggle_attack('summon')
			attack_type = 'summon'
			summonCooldown.start()
		elif rnum > 20 and rnum <= 30 and tpCooldown.is_stopped():
			toggle_attack("tp")
			attack_type = 'tp'
			tpCooldown.start()
		else:
			toggle_attack("melee")
			attack_type = 'melee'
		return
		
	elif phase == 2:
		if rnum <= 30 and summonCooldown.is_stopped():
			toggle_attack('summon')
			attack_type = 'summon'
			summonCooldown.start()
		elif rnum > 30 and rnum <= 50 and tpCooldown.is_stopped():
			toggle_attack("tp")
			attack_type = 'tp'
			tpCooldown.start()
		else:
			toggle_attack("melee")
			attack_type = 'melee'
		return
		
	elif phase == 3:
		if rnum <= 40 and summonCooldown.is_stopped():
			toggle_attack('summon')
			attack_type = 'summon'
			summonCooldown.start()
		elif rnum > 40 and rnum <= 80 and tpCooldown.is_stopped():
			toggle_attack("tp")
			attack_type = 'tp'
			tpCooldown.start()
		else:
			toggle_attack("melee")
			attack_type = 'melee'
		return
		
	###print(attack_type)
	
		
func toggle_attack(attack_name):
	if attack_name ==  "summon":
		can_summon = true
		can_melee = false
		can_tp = false
		return
	if attack_name ==  "melee":
		can_summon = false
		can_melee = true
		can_tp = false
		return
	if attack_name ==  "tp":
		can_summon = false
		can_melee = false
		can_tp = true
		return


func tp_attack():
	work_in_progress = true
	change_state("skill")
	await anim.animation_finished
	var t = 0
	var duration = 2
	while t < duration:
		t += get_process_delta_time()
		##print(t)
		sprite.modulate.a -= t
	##print(sprite.modulate.a , "spirtee")
	if sprite.modulate.a <= 0:
		if not player.get_child(0).flip_h:
			global_position.x = player.global_position.x - 150
			global_position.y = player.global_position.y
			flip_reaper(1)
		else:
			global_position.x = player.global_position.x + 150
			global_position.y = player.global_position.y
			flip_reaper(-1)
			##print('right')
		sprite.modulate.a = 1

func check_checkpoint():
	var restpoint1 = (global_position - get_parent().get_child(0).get_child(0).global_position) 
	var restpoint2 = (global_position - get_parent().get_child(1).get_child(0).global_position)
	if restpoint1 == Vector2.ZERO:
		flip_reaper(-1)
		#attack_type = ''
		return 1
	elif restpoint2 == Vector2.ZERO:
		flip_reaper(1)
		#attack_type = ''
		return 2
	else: 
		return null
	
func tp_back():
	if work_in_progress:
		returning = false
		return
	if not restTIme.is_stopped():
		returning = false
		return
	returning = true
	stop_chasing()
	var restpoint1 = abs(global_position.x - get_parent().get_child(0).get_child(0).global_position.x) 
	var restpoint2 = abs(global_position.x - get_parent().get_child(1).get_child(0).global_position.x) 
	var restpoint = null
	if restpoint1 > restpoint2:
		restpoint = get_parent().get_child(0).get_child(0).global_position
		###print('rightOne')
		
	elif restpoint1 < restpoint2:
		restpoint = get_parent().get_child(1).get_child(0).global_position 
		###print("leftone")
	
	#if check_checkpoint() == 1:
		#flip_reaper(1)
	#elif check_checkpoint() == 2:
		#flip_reaper(-1)
	
	await anim.animation_finished
	velocity = Vector2.ZERO
	change_state("skill")
	await anim.animation_finished
	change_state('idle')	
	global_position = restpoint
	returning = false
	restTIme.start()
	

func _on_summon_cooldown_timeout() -> void:
	summonCooldown.stop()

func _on_tp_cooldown_timeout() -> void:
	tpCooldown.stop()

func _on_rest_timeout() -> void:
	restTIme.stop()

func deal_melee_damage():
	if not get_player_in_area(attack_radius):
		return

	player.take_damage(
		10,
		player.global_position.x - global_position.x,
		4500
	)
	
func take_damage(amount):
	health -= amount
	restTIme.stop()

	if damage_flash_running:
		return

	damage_flash_running = true

	# Flash white / red
	sprite.modulate = Color(1, 0.3, 0.3, 1)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
	tween.finished.connect(func():
		damage_flash_running = false
	)
	
#
#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#if anim_name.begins_with('Attack'):
		#if in_attack:
			#player.take_damage(10 , player.global_position.x - global_position.x, 4500)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'Death':
		Global.fight_started = false
		queue_free()
		
		
func play_custcene():
	sprite.modulate.a = 0
	cutscene = true
	var restpoint = get_parent().get_child(0).get_child(0).global_position
	global_position = restpoint
	var t = 0
	var duration = 1
	while t < duration:
		t += get_process_delta_time()
		sprite.modulate.a += t
	change_state('skill')
	await anim.animation_finished
	global_position.y = player.global_position.y
	global_position.x = player.global_position.x - 100 
	print('attack tppp')
	anim.stop()
	anim.play("Attack 2")
	await anim.animation_finished
	print('Doneee')
	anim.stop()
	anim.play('Idle')
	return true

func stop_cutscene():
	cutscene = false
