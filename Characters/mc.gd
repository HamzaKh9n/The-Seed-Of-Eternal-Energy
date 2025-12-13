extends CharacterBody2D

# -----------------------------------------------------
# MOVEMENT VARIABLES
# -----------------------------------------------------
@export var move_speed := 600.0
@export var acceleration := 30.0
@export var deceleration := 25.0
@export var jump_force := -900.0
@export var gravity := 3000.0
@export var ghost_scale : float

@export var low_gravity := 1000.0
@export var high_gravity := 3000.0

@onready var cam = $Camera2D
@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var attack_radius = $AttackRadius
@onready var fixed_scale = scale.x


var cutscene =  false
# AfterImage

var AfterImage = preload("res://Global/ghost.tscn")
var afterimage_cooldown := 0.0
var ghost_position = null
var ghost = null


# -----------------------------------------------------
# STATES
# -----------------------------------------------------
var was_on_floor := false
var attack = false 
var cooldown = false
var combo = 0
var flipped = false
var is_hurt: bool = false
var hurt_duration: float = 0.25
var hurt_timer: float = 0.0
var can_hurt = true
var invincible_time: float = 1.0
var flash_speed: float = 0.1
var can_push = true

var can_dash = true
var is_dashing = false
@export var dash_speed : float = 1800.0
@onready var dash_cooldown = $"Dash Cooldown"
@onready var dash_time = $"Dash Time"
var air_dash_used = false


#attack
var attack_timer := 0.0
var attack_timeout := 0.35   # slightly longer than longest attack anim


func _ready() -> void:
	$Dust.global_position.x = global_position.x - 80
	$Dust.visible = false
	anim.play("Idle")


func _physics_process(delta: float) -> void:
	if cutscene:
		return
	
	var applied_gravity := false
	#print("Is Hurt " , is_hurt)
	if Global.stop:
		anim.play("Idle")
		velocity.x = 0
		if not is_on_floor():
			if not applied_gravity:
				velocity.y += gravity * delta
				applied_gravity = true
		move_and_slide()
		return

	# ----------------------------------------------------
	# ATTACK FAIL-SAFE (ANTI FREEZE)
	# ----------------------------------------------------
	if attack:
		attack_timer -= delta

		if attack_timer <= 0:
			_force_exit_attack("timeout")



	# PLAYER DEATH
	if Global.health <= 0:
		Global.deaths += 1
		SaveGame.save_game()
		anim.play("Death")
		var tree = get_tree()
		await anim.animation_finished
		Global.health = 100
		Global.frags -= 10
		if Global.frags <= 0:
			Global.frags = 0
		var level = Global.Level
		match level:
			1:
				await Global.safe_frame()
				tree.change_scene_to_file("res://Levels/level_1.tscn")
			2:
				await Global.safe_frame()
				tree.change_scene_to_file("res://Levels/level_2.tscn")
			3:
				await Global.safe_frame()
				tree.change_scene_to_file("res://Levels/boss_arena_1.tscn")
		return

	# HURT STATE
	if is_hurt and is_on_floor()		:
		hurt_timer -= delta

		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)

		if not applied_gravity:
			velocity.y += gravity * delta
			applied_gravity = true

		if hurt_timer <= 0:
			is_hurt = false
			print('Reseted IS HURT STATEEE')
			velocity.x = 0   # 🔴 HARD STOP (CRITICAL)
		anim.play("Idle")

		move_and_slide()
		return


	# ----------------------------------------------------
	# MOVEMENT INPUTS
	# ----------------------------------------------------
	var dir_right := 1 if Input.is_action_pressed("D") else 0
	var dir_left := 1 if Input.is_action_pressed("A") else 0
	var direction := dir_right - dir_left

	# DASH DIRECTION (same as facing)
	var dash_direction := -1 if sprite.flip_h else 1

	# Flip sprite only when not attacking
	if direction != 0 and not attack:
		sprite.flip_h = direction < 0
		$Dust.flip_h = !sprite.flip_h
		if sprite.flip_h:
			$Dust.global_position.x = global_position.x + 80
		else:
			$Dust.global_position.x = global_position.x - 80
		

	# ----------------------------------------------------
	# DASH INPUT (FIXED — WORKS ANY TIME)
	# ----------------------------------------------------
	if Input.is_action_just_pressed("Dash") and not attack and Global.dash:
		var allow_dash := false

		if is_on_floor():
			allow_dash = can_dash
		else:
			allow_dash = can_dash and not air_dash_used

		if allow_dash:
			is_dashing = true
			can_dash = false
			
			
			if is_dashing:
				spawn_afterimage()

					
			if not is_on_floor():
				air_dash_used = true

			anim.play("Dash")
			$Dust.visible = true
			$Dust/DustanimationPlayer.play("Dust")
			$Dust/CPUParticles2D.emitting = true
			
			dash_cooldown.start()
			dash_time.start()

			velocity.y = 0
			velocity.x = dash_direction * dash_speed
			await dash_time.timeout
			velocity.x = 0
			is_dashing = false
	# ----------------------------------------------------
	# DASH EARLY RETURN (NO GRAVITY / NO INTERRUPT)
	# ----------------------------------------------------
	if is_dashing:
		move_and_slide()
		return


	# ----------------------------------------------------
	# HORIZONTAL MOVEMENT
	# ----------------------------------------------------
	if not attack:
		if direction != 0:
			velocity.x = lerp(velocity.x, direction * move_speed, acceleration * delta)
			if is_on_floor() and anim.current_animation not in ["Land"]:
				anim.play("Run")
		else:
			if is_on_floor():
				velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
				if anim.current_animation not in ["Land", "Jump", "Fall", "Dash"]:
					anim.play("Idle")

	# RESET AIR DASH ON GROUND
	if is_on_floor():
		air_dash_used = false

	# ----------------------------------------------------
	# JUMP
	# ----------------------------------------------------
	if is_on_floor() and Input.is_action_just_pressed("Space") and not attack:
		$JumpBreath.play()
		velocity.y = jump_force
		anim.play("Jump")

	# ----------------------------------------------------
	# AIR MOVEMENT + GRAVITY
	# ----------------------------------------------------
	# AIR MOVEMENT + GRAVITY (ALWAYS APPLY, EVEN DURING ATTACK)
# AIR MOVEMENT + GRAVITY (ALWAYS APPLY GRAVITY)
	if not is_on_floor():

		var air_dir := Input.get_action_strength("D") - Input.get_action_strength("A")

		# Allow air steering ONLY if not attacking
		if not attack:
			if air_dir != 0:
				velocity.x = lerp(velocity.x, air_dir * (move_speed * 0.6), 8 * delta)
			else:
				velocity.x = lerp(velocity.x, 0.0, 12 * delta)

		# GRAVITY MUST ALWAYS APPLY (EVEN DURING ATTACK)
		if velocity.y < 0:
			var g := low_gravity if Input.is_action_pressed("Space") else high_gravity
			velocity.y += g * delta
		else:
			velocity.y += gravity * delta

		if velocity.y > 0 and anim.current_animation != "Fall" and not attack:
			anim.play("Fall")



	# ----------------------------------------------------
	# LAND
	# ----------------------------------------------------
	if not was_on_floor and is_on_floor() and velocity.y >= 0:
		if anim.current_animation not in ["Hurt"] and not attack:
			anim.play("Land")

	was_on_floor = is_on_floor()

	# ----------------------------------------------------
	# ATTACK INPUT
	# ----------------------------------------------------
	if Input.is_action_just_pressed("Attack") and not cooldown:
		is_hurt = false
		attack = true
		cooldown = true
		attack_timer = attack_timeout

		$"Attack Cooldown".start()
		$"Combo Cooldown".start()

		velocity.x = 0

		match combo:
			0: anim.play("Attack 1")
			1: anim.play("Attack 2")
			2: anim.play("Attack 3")

		combo += 1
		if combo > 2:
			combo = 0

	move_and_slide()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Land":
		anim.play("Idle")

	if anim_name.begins_with("Attack"):
		is_hurt =  false
		attack = false
		Do_attack()


func Do_attack():
	for area in attack_radius.get_overlapping_areas():
		if area.is_in_group("EnemyHitbox"):
			var enemy = area.get_parent()
			enemy.take_damage(Global.Power)
			if Global.lifesteal:
				Global.health += Global.power * 0.25
			var dir_to_enemy: float = sign(enemy.global_position.x - global_position.x)
			var knock_force: float = 150.0
			velocity.x = -dir_to_enemy * knock_force
			shake_camera(0.25, 18)
			await pause_brief(0.05, 0.25)


func _on_attack_cooldown_timeout() -> void:
	cooldown = false


func _on_combo_cooldown_timeout() -> void:
	combo = 0


func take_damage(amount, dir, power) -> void:
	if can_hurt:
		Global.health -= amount
		var knock_dir := signi(dir)
		if knock_dir == 0:
			knock_dir = 1
		is_hurt = true
		hurt_timer = hurt_duration
		var k_power := clampf(power, 200, 800)
		velocity = Vector2(knock_dir * k_power, -k_power * 0.15)
		anim.play("Hurt")
		shake_camera(0.25, 18)
		await pause_brief(0.05, 0.1)
		can_hurt = false
		start_invincibility()


func shake_camera(duration: float = 0.5, magnitude: float = 8.0) -> void:
	var original_mode = cam.process_mode
	cam.process_mode = Node.PROCESS_MODE_ALWAYS
	var original_pos = cam.position
	var timer = 0.0
	while timer < duration:
		cam.position = original_pos + Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
		await Global.safe_frame()
		timer += 0.016
	cam.position = original_pos
	cam.process_mode = original_mode


var _is_time_scaled := false
func pause_brief(duration: float, slow: float = 0.1) -> void:
	if _is_time_scaled:
		return
	_is_time_scaled = true
	var original := Engine.time_scale
	Engine.time_scale = slow
	await get_tree().create_timer(duration, false, true).timeout
	Engine.time_scale = original
	_is_time_scaled = false


func start_invincibility() -> void:
	if can_hurt:
		return
	var timer = 0.0
	while timer < invincible_time:
		sprite.modulate = Color(1, 1, 1, 1)
		await get_tree().create_timer(flash_speed).timeout
		sprite.modulate = Color(1, 1, 1, 0.4)
		await get_tree().create_timer(flash_speed).timeout
		timer += flash_speed * 2
	sprite.modulate = Color(1, 1, 1, 1)
	can_hurt = true
	velocity.x = 0
	is_hurt = false


func _on_dash_cooldown_timeout() -> void:
	can_dash = true
	is_dashing = false


func _on_dustanimation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Dust":
		$Dust.visible = false
		
		
func spawn_afterimage():
	ghost = AfterImage.instantiate()
	ghost.flip_h = sprite.flip_h
	var dot_right = ghost.get_child(1)
	var dot_left = ghost.get_child(2)
	dot_left.visible = sprite.flip_h
	dot_right.visible = !sprite.flip_h
	
	ghost.set_property(position , sprite.scale*ghost_scale)
	get_parent().add_child(ghost)
	$GhostTimer.start()


func _on_ghost_timer_timeout() -> void:
	if is_dashing:
		spawn_afterimage()


func play_cutscene_1():
	cutscene = true
	anim.stop()
	sprite.play("Walk")
	velocity.x = 200
	move_and_slide()
	
func stop_cutscene_1():
	cutscene = false
	anim.play("Idle")
	sprite.stop()
	velocity.x = 0
	#move_and_slide()

func _force_exit_attack(reason := "") -> void:
	# Optional debug
	#print("FORCE EXIT ATTACK:", reason)

	attack = false
	cooldown = false
	velocity.x = 0

	if is_on_floor():
		anim.play("Idle")
	else:
		anim.play("Fall")
