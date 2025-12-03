extends CharacterBody2D


@export var speed: float = 200
@export var attack_cooldown: float = 1.5
var cooldown = false
var player_area: Area2D = null
var in_atk_radius = false
var can_attack := true
var attack = false

@export var gravity = 1200
@onready var attack_position = 10
@onready var anim = $AnimationPlayer


func _ready():
	set_physics_process(true)
	$Chase.area_exited.connect(_on_chase_exited)
	$PlayerDetect.area_entered.connect(_on_player_detect_entered)
	$PlayerDetect.area_exited.connect(_on_player_detect_exited)
	$AttackRadius.area_entered.connect(_on_attack_radius_entered)
	$Hitbox.area_entered.connect(_on_hitbox_area_entered)
	$Detection.area_entered.connect(_on_detection_area_entered)
	$AttackRadius.area_exited.connect(_on_attack_radius_area_exited)

func _physics_process(delta):
	
	if is_on_wall():
		if not attack:
			anim.play("Idle")
		else:
			print("OOps Attack fucked upd")
		
	
	if velocity.x != 0:
		anim.play('Walk')
	else:
		if not attack:
			anim.play('Idle')
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var dir = Vector2.ZERO
		
	if player_area:    # Chase logic
		var player_distance = (player_area.get_parent().global_position - global_position)
		dir = player_distance.normalized()
		
		
		
		if abs(player_distance.x) >= 175:
			velocity.x = dir.x * speed
			if not attack:
				anim.play("Walk")
		else:
			velocity.x = 0
			if not attack:
				#print('Stopped and played Idled')
				anim.play("Idle")
	else:
		anim.play("Idle")
	
	if dir.x > 0:
		$AnimatedSprite2D.flip_h = true
		$AttackRadius.position.x = attack_position + 150
	else:
		$AnimatedSprite2D.flip_h = false
		$AttackRadius.position.x = attack_position

	move_and_slide()


# -----------------------------------------
#               CHASE AREA
# -----------------------------------------

func _on_chase_exited(area: Area2D):
	if area.is_in_group('PlayerHitbox'):
		if area == player_area:
			player_area = null


# -----------------------------------------
#          PLAYER DETECT AREA
# -----------------------------------------
func _on_player_detect_entered(area: Area2D):
	if area.is_in_group("PlayerHitbox"):
		in_atk_radius = true
		print('Player Detected')
		damage_player()


func _on_player_detect_exited(area: Area2D):
	if area.is_in_group("PlayerHitbox"):
		anim.play("Walk")
		print('Exitedd')
		print("radius " , in_atk_radius)
		attack = false
		can_attack = true


# -----------------------------------------
#         ATTACK (Damage)
# -----------------------------------------
func _on_attack_radius_entered(area: Area2D):
	in_atk_radius = true
	if not can_attack:
		return

	if area.is_in_group("PlayerHitbox"):
		print('Player Entered the area')
		await damage_player()
		



func damage_player():
	if in_atk_radius:
		if not cooldown:
			print("Damaging the player")
			print('CanAttack' , can_attack , "attack" , attack)
			attack_reset()
			if can_attack:
				attack = true
				await anim.animation_finished
				can_attack = false
				if player_area:
					anim.play("Attack 1")
					
	else:
		return
		



func attack_reset():
	cooldown = true
	await get_tree().create_timer(attack_cooldown).timeout
	cooldown = false
	
	# only allow next attack if player is still in the radius
	if in_atk_radius:
		can_attack = true
	else:
		can_attack = false

	# reset attack state fully when player left
	if not in_atk_radius:
		attack = false
		anim.play("Idle")
		
	damage_player()
	


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'Attack 1':
		if in_atk_radius:
			player_area.get_parent().take_damage(10 , (player_area.get_parent().global_position.x - global_position.x) , 700)
		if anim.current_animation != 'Walk':
			anim.play('Idle')
		attack = false
		can_attack = false
		print(anim.current_animation)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group('PlayerHitbox'):
		area.get_parent().take_damage(10 , (player_area.get_parent().global_position.x - global_position.x) , 500)
		
func _on_detection_area_entered(area: Area2D) -> void:
	if area.is_in_group('PlayerHitbox'):
		player_area = area
		


func _on_attack_radius_area_exited(area: Area2D) -> void:
	if area.is_in_group("PlayerHitbox"):
		in_atk_radius = false
		attack = false
		can_attack = true
		
		if anim.current_animation != "Walk":
			anim.play("Idle")
