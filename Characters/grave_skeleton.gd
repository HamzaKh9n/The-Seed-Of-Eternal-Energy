extends CharacterBody2D

# -----------------------------
#       EXPORT VARIABLES
# -----------------------------
@export var speed: float = 300
@export var gravity: float = 1200
@export var attack_position: float = 10
@export var energy_fragment_scene: PackedScene 


# -----------------------------
#       INTERNAL VARIABLES
# -----------------------------
var health = 100
var spawn: bool = false
var alive: bool = false
var player_area: Area2D = null
var in_atk_radius: bool = false
var can_attack: bool = false
var spawning = false
var spawned = false
var has_dropped = false

# -----------------------------
#       KNOCKBACK / STUN SYSTEM
# -----------------------------
var knockback := true
var knockback_force := Vector2.ZERO
var knockback_duration := 0.2
var knockback_timer := 0.0

var stunned := false
var stun_time := 0.0
var stun_timer := 0.0

# -----------------------------
#       NODE REFERENCES
# -----------------------------
@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var chase_area = $Chase
@onready var detect_area = $PlayerDetect
@onready var attack_area = $AttackRadius
@onready var hitbox_area = $Hitbox
@onready var attack_cooldown = $Attack_Cooldown
var is_on_cooldown = true


# -----------------------------
#       PHYSICS PROCESS
# -----------------------------
func _physics_process(delta: float) -> void:
	if Global.stop:
		if spawned:
			anim.play("Idle")
		else:
			anim.play("Nothing")
		if not is_on_floor():
			velocity.y = gravity * delta
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Death
	if health <= 0:
		anim.play("Death")
		if has_dropped:
			return
		has_dropped = true
		var fragment = energy_fragment_scene.instantiate()
		fragment.global_position = global_position
		get_parent().add_child(fragment)
		await anim.animation_finished
		queue_free()
		return

	# Not spawned yet
	if not spawn:
		velocity = Vector2.ZERO
		move_and_slide()
		return


	# -----------------------------
	#      STUN LOGIC
	# -----------------------------
	if stunned:
		stun_timer -= delta
		velocity = Vector2.ZERO
		if not is_on_floor():
			velocity.y += gravity * delta
		if stun_timer <= 0:
			stunned = false
		move_and_slide()
		return


	# -----------------------------
	#      KNOCKBACK LOGIC
	# -----------------------------
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity.x = knockback_force.x
		velocity.y += gravity * delta
		move_and_slide()
		return
	else:
		# Smooth slowdown
		knockback_force = knockback_force.lerp(Vector2.ZERO, 10 * delta)


	# -----------------------------
	#      CHASE + ATTACK LOGIC
	# -----------------------------
	if player_area and alive:
		var player_distance = (player_area.get_parent().global_position - global_position)
		var dir = player_distance.normalized()

		# Flip sprite
		if dir.x > 0:
			sprite.flip_h = false
			attack_area.position.x = attack_position
		else:
			sprite.flip_h = true
			attack_area.position.x = attack_position - 150

		# Walk toward player
		if abs(player_distance.x) >= 75:
			velocity.x = dir.x * speed
			if anim.current_animation not in ["Attack", "Spawn", "Damage", "Death"]:
				anim.play("Walk")
		else:
			velocity.x = 0
			if anim.current_animation not in ["Attack", "Spawn", "Damage", "Death"]:
				anim.play("Idle")

		# Attack
		for area in attack_area.get_overlapping_areas():
			if area.is_in_group("PlayerHitbox"):
				in_atk_radius = true
				
				if can_attack and anim.current_animation not in ["Damage", "Death"]:
					can_attack = false
					anim.play("Attack")
				elif not can_attack and is_on_cooldown:
					attack_cooldown.start()
					is_on_cooldown = false
					print('timer Started')
					print(can_attack)
				break
				
			else:
				in_atk_radius = false

		# Touch damage
		for area in hitbox_area.get_overlapping_areas():
			if area.is_in_group("PlayerHitbox"):
				area.get_parent().take_damage(10, area.get_parent().global_position.x - global_position.x, 1500)

	else:
		velocity = Vector2.ZERO
		if alive and anim.current_animation not in ["Attack", "Spawn", "Damage", "Death"]:
			anim.play("Idle")
		elif not alive:
			anim.play("Nothing")

	move_and_slide()


# -----------------------------
#       SPAWN HANDLER
# -----------------------------
func spawn_skeleton():
	spawning = true
	anim.play("Spawn")
	await anim.animation_finished

	chase_area.area_entered.connect(_on_chase_entered)
	chase_area.area_exited.connect(_on_chase_exited)
	detect_area.area_exited.connect(_on_detect_exited)
	hitbox_area.area_entered.connect(_on_hitbox_entered)

	for area in chase_area.get_overlapping_areas():
		if area.is_in_group("PlayerHitbox"):
			_on_chase_entered(area)

	Global.encounters += 1
	spawning = false
	spawned = true


# -----------------------------
#       AREA SIGNALS
# -----------------------------
func _on_chase_entered(area):
	if area.is_in_group("PlayerHitbox"):
		player_area = area

func _on_chase_exited(area):
	if area == player_area:
		player_area = null

func _on_detect_exited(area):
	if area.is_in_group("PlayerHitbox"):
		if alive and anim.current_animation not in ["Attack", "Spawn", "Damage", "Death"]:
			anim.play("Walk")

func _on_hitbox_entered(area):
	if area.is_in_group("PlayerHitbox"):
		area.get_parent().take_damage(10, area.get_parent().global_position.x - global_position.x, 500)


# -----------------------------
#       ATTACK COOLDOWN
# -----------------------------
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Spawn":
		alive = true
		spawn = true
		anim.play("Idle")

	elif anim_name == "Attack":
		for area in attack_area.get_overlapping_areas():
			if area.is_in_group("PlayerHitbox"):
				area.get_parent().take_damage(10, area.get_parent().global_position.x - global_position.x, 1500)

		# REAL FIX — cooldown reliably restarts
		can_attack = false
		is_on_cooldown = true
	


# -----------------------------
#       DAMAGE & KNOCKBACK
# -----------------------------
func take_damage(amount):
	health -= amount
	anim.play("Damage")
	print(health)
	
	if spawned:
		if knockback and anim.current_animation != "Attack":
			var dir = sign(player_area.get_parent().global_position.x - global_position.x)
			knockback_force = Vector2(-dir * 600, -150)
			knockback_timer = knockback_duration

			stunned = true
			stun_timer = stun_time


func _on_spawn_area_entered(area):
	if area.is_in_group("PlayerHitbox"):
		if not spawned:
			spawn_skeleton()
			spawned = true


func _on_attack_cooldown_timeout() -> void:
	can_attack = true
	if in_atk_radius and alive:
		anim.play("Attack")
