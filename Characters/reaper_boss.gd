extends CharacterBody2D

@onready var attack_radius = $AttackRadius
@onready var melee_radius = $MeleeRadius
@onready var hitbox = $Hitbox
@onready var summon_point = $SummonPoint
@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var restTIme = $Rest


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

var state = "idle"
var stun = false
var returning = false
var canThink = false


var health = 500
var max_health = 500
var phase = 1		

func _ready() -> void:
	summonCooldown.start()
	tpCooldown.start()
	


func _physics_process(_delta: float) -> void:
	if not Global.fight_started:
		change_state("idle")
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
	var in_melee = get_player_in_area(melee_radius)
	var in_attack = get_player_in_area(attack_radius)
	#var in_hitbox = get_player_in_area(hitbox)
	
	distance = player.global_position.x - global_position.x
	direction = (player.global_position - global_position).normalized()
	
	if not returning and restTIme.is_stopped():
		##print('jjjjjjjjjjjjjjjjjj')
		if in_melee:
			attack_type = 'melee'
		velocity.x = 0
		var prev_type = attack_type
		chose_attack()
		#if prev_type != attack_type:
		#print(attack_type)
		if attack_type == "":
			attack_type = 'summon'	
		elif attack_type == 'tp' and not work_in_progress and can_tp:
			#print("tpppppppppppppppppppp")
			await tp_attack()
			stun = true
			await get_tree().create_timer(2).timeout
			stun = false
			work_in_progress = false
		elif attack_type == 'melee' and not work_in_progress and can_melee and not in_attack:
			##print('chasing')
			work_in_progress = true
			while work_in_progress:
				chase_player()
				await Global.safe_frame()
			
		elif attack_type == 'summon' and not work_in_progress and can_summon:
			work_in_progress = true
			#print('wanna summon')
			var ghost = summon.instantiate()
			#summon_point.add_child(ghost)
			await anim.animation_finished
			while check_checkpoint() == null:
				await Global.safe_frame()
			##print('changed state to summon')
			change_state('summon')
			await anim.animation_finished
			get_parent().add_child(ghost)
			ghost.global_position = summon_point.get_child(0).global_position
			ghost.scale = Vector2(4, 4)
			change_state('idle')
			#print(anim.current_animation)
			work_in_progress = false
		
	if in_attack and not attacking and attack_cooldown.is_stopped() and not returning:
		work_in_progress = false
		var rnum = randi_range(0,1)
		##print("Atttacking" , rnum)
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
	##print('Changing State' , x)
	if x == 'summon':
		anim.stop()
		anim.play('Summon')
		##print("Quitt")
		return
	
	if not x == state:	
		#print("stopped anim")
		anim.stop()
	state = x
	
	if state == 'idle':
		##print('yeahhh Idlee')
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
		#print("Player Got Damaged")
		await attack_cooldown.timeout
		attack_cooldown.stop()
	
func check_phase():
	
	var health_percent = (health/max_health * 100)
	
	if health_percent >= 75:
		phase = 1 	
		
	elif health_percent >= 35 and health_percent <75:
		phase = 2
		tpCooldown.wait_time = 15
		summonCooldown = 15
	elif health_percent<35 and health_percent > 0:
		phase = 3
		tpCooldown.wait_time = 5
		summonCooldown = 10
	if health_percent <= 0:
		phase = 4
	
func chose_attack():
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
		
	##print(attack_type)
	
		
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
		#print(t)
		sprite.modulate.a -= t
	#print(sprite.modulate.a , "spirtee")
	if sprite.modulate.a <= 0:
		if not player.get_child(0).flip_h:
			global_position.x = player.global_position.x - 150
			global_position.y = player.global_position.y
		else:
			global_position.x = player.global_position.x + 150
			global_position.y = player.global_position.y
			#print('right')
		sprite.modulate.a = 1

func check_checkpoint():
	var restpoint1 = (global_position - get_parent().get_child(0).get_child(0).global_position) 
	var restpoint2 = (global_position - get_parent().get_child(1).get_child(0).global_position)
	if restpoint1 == Vector2.ZERO:
		flip_reaper(-1)
		return 1
	elif restpoint2 == Vector2.ZERO:
		flip_reaper(1)
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
	var restpoint1 = abs(global_position.x - get_parent().get_child(0).get_child(0).global_position.x) 
	var restpoint2 = abs(global_position.x - get_parent().get_child(1).get_child(0).global_position.x) 
	var restpoint = null
	if restpoint1 > restpoint2:
		restpoint = get_parent().get_child(0).get_child(0).global_position
		##print('rightOne')
		
	elif restpoint1 < restpoint2:
		restpoint = get_parent().get_child(1).get_child(0).global_position 
		##print("leftone")
	
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
	
func take_damage(amount):
	health -= amount
	print(health)
