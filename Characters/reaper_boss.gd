extends CharacterBody2D

@onready var attack_radius = $AttackRadius
@onready var melee_radius = $MeleeRadius
@onready var hitbox = $Hitbox
@onready var summon_point = $SummonPoint
@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")

@export var move_speed =  150
var distance = null


var state = "Idle"

var health = 500

func _physics_process(delta: float) -> void:
	if not Global.fight_started:
		change_state("idle")
		return
	
	var in_melee = get_player_in_area(melee_radius)
	var in_attack = get_player_in_area(attack_radius)
	var in_hitbox = get_player_in_area(hitbox)
	
	distance = player.global_position.x - global_position.x
	
	
	if in_melee:
		chase_player()
	else:
		velocity.x = 0
	
	move_and_slide()


func get_player_in_area(area):
	var areas = area.get_overlapping_areas()
	for i in areas:
		if i.is_in_group("PlayerHitbox"):
			return true
	return false
		
func chase_player():
	var dir = 0
	
	if distance > 0:
		dir = 1
		sprite.flip_h = false
		attack_radius.position.x = 0
		summon_point.position.x = 0
		
	elif distance < 0:
		dir = -1
		sprite.flip_h = true
		attack_radius.position.x = -55
		summon_point.position.x = -100
		
	if abs(distance )<= 175:
		dir = 0
	velocity.x = dir * move_speed
	
	move_and_slide()
	
	
	
func change_state(x):
	state = x
	if state == 'idle':
		anim.play("Idle")
	elif state == "attack1":
		anim.play("Attack 1")
	elif state == "attack2":
		anim.play("Attack 2")
	elif state == 'death':
		anim.play("Death")
	elif state == 'summon':
		anim.play("Summon")
	elif state == "skill":
		anim.play("Skill")
		
		
		
		
