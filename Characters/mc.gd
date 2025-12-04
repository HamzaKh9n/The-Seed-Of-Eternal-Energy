extends CharacterBody2D

# -----------------------------------------------------
# MOVEMENT VARIABLES
# -----------------------------------------------------
@export var move_speed := 600.0
@export var acceleration := 30.0
@export var deceleration := 25.0
@export var jump_force := -900.0
@export var gravity := 3000.0

# Hollow Knight variable jump (FIXED)
@export var low_gravity := 1000.0   ### FIXED (was too low)
@export var high_gravity := 3000.0 ### FIXED (better cutoff)

@onready var cam = $Camera2D
@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var attack_radius = $AttackRadius

# -----------------------------------------------------
# STATES
# -----------------------------------------------------
var was_on_floor := false
var attack = false
var cooldown = false
var combo = 0

var is_hurt: bool = false
var hurt_duration: float = 0.25
var hurt_timer: float = 0.0

var can_hurt = true
var invincible_time: float = 1.0
var flash_speed: float = 0.1
var can_push = true

func _ready() -> void:
	anim.play("Idle")


func _physics_process(delta: float) -> void:

	if Global.health <= 0:
		anim.play("Death")
		var tree = get_tree()
		await anim.animation_finished
		Global.health = 100
		Global.frags -= 10
		if Global.frags <= 0:
			Global.frags = 0
		var level = Global.Level
		print(level)
		match level:
			1:
				await tree.process_frame
				tree.change_scene_to_file("res://Levels/level_1.tscn")

			3:
				await tree.process_frame
				tree.change_scene_to_file("res://Emperor's Grave Scenes/graves.tscn")
	# -----------------------------------------------------
	# Handle Hurt State First
	# -----------------------------------------------------
	
	if is_hurt:
		hurt_timer -= delta
		# soft stop
		velocity.x = lerp(velocity.x, 0.0, 6.0 * delta)
		velocity.y += gravity * delta

		if hurt_timer <= 0:
			is_hurt = false
		
		move_and_slide()
		was_on_floor = is_on_floor()
		return


	# -----------------------------------------------------
	# HORIZONTAL INPUT
	# -----------------------------------------------------
	var direction := 0
	if Input.is_action_pressed("A"):
		direction = -1
	elif Input.is_action_pressed("D"):
		direction = 1

	# Flip sprite
	if direction != 0 and not attack:  ### FIXED (attack no flip)
		sprite.flip_h = direction < 0


	# -----------------------------------------------------
	# HORIZONTAL MOVEMENT
	# -----------------------------------------------------
	if not attack: ### FIXED (movement disabled only during attack)
		if direction != 0:
			velocity.x = lerp(velocity.x, direction * move_speed, acceleration * delta)
			if is_on_floor() and anim.current_animation not in ["Land"]:
				anim.play("Run")
		else:
			velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
			if is_on_floor() and anim.current_animation not in ["Land", "Jump" , "Death"]:
				anim.play("Idle")


	# -----------------------------------------------------
	# JUMP
	# -----------------------------------------------------
	if is_on_floor() and Input.is_action_just_pressed("Space") and not attack:
		$JumpBreath.play()
		anim.play("Jump")
		velocity.y = jump_force  


	# -----------------------------------------------------
	# VARIABLE JUMP (HOLLOW KNIGHT FIXED)
	# -----------------------------------------------------
	if not is_on_floor():
		if velocity.y < 0:  # rising
			if Input.is_action_pressed("Space"):
				velocity.y += low_gravity * delta
			else:
				velocity.y += high_gravity * delta
		else:
			velocity.y += gravity * delta


	# -----------------------------------------------------
	# AIR ANIMATIONS PRIORITY
	# -----------------------------------------------------
	if not is_on_floor() and not attack:
		if velocity.y > 0:
			anim.play("Fall")
		elif velocity.y < 0:
			anim.play("Jump")


	# -----------------------------------------------------
	# LANDING
	# -----------------------------------------------------
	if not was_on_floor and is_on_floor() and velocity.y >= 0:
		if anim.current_animation not in ["Jump", "Fall", "Hurt"]:
			anim.play("Land")

	was_on_floor = is_on_floor()


	# -----------------------------------------------------
	# ATTACK FIXED ENTIRELY
	# -----------------------------------------------------
	if Input.is_action_just_pressed("Attack") and not cooldown:

		attack = true
		cooldown = true

		$"Attack Cooldown".start()
		$"Combo Cooldown".start()

		# freeze movement
		velocity.x = 0

		var push = 0

		match combo:
			0:
				anim.play("Attack 1")
				push = 200
			1:
				anim.play("Attack 2")
				push = 200
			2:
				anim.play("Attack 3")
				push = 300

		# apply push direction
		if sprite.flip_h:
			push = -push

		if is_on_floor():
			velocity.x += push

		combo += 1
		if combo > 2:
			combo = 0

	# -----------------------------------------------------
	# MOVE
	# -----------------------------------------------------
	move_and_slide()



# -----------------------------------------------------
# ANIMATION FINISHED
# -----------------------------------------------------
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Land":
		anim.play("Idle")

	if anim_name.begins_with("Attack"):  ### FIXED
		attack = false
		move_speed = 350
		Do_attack()
		

func Do_attack():
	for area in attack_radius.get_overlapping_areas():
		if area.is_in_group("EnemyHitbox"):
			var enemy = area.get_parent()

			# Deal damage
			enemy.take_damage(Global.Power)

			# Player knockback (small, controlled)
			var dir_to_enemy: float = sign(enemy.global_position.x - global_position.x)
			var knock_force: float = 150.0

			velocity.x = -dir_to_enemy * knock_force

			shake_camera(0.25, 18)
			await pause_brief(0.02, 0.06)

		

# -----------------------------------------------------
# ATTACK COOLDOWNS
# -----------------------------------------------------
func _on_attack_cooldown_timeout() -> void:
	cooldown = false


func _on_combo_cooldown_timeout() -> void:
	combo = 0


# -----------------------------------------------------
# DAMAGE / KNOCKBACK
# (unchanged)
# -----------------------------------------------------
func take_damage(amount, dir, power) -> void:
	if can_hurt:
		Global.health -= amount
		if Global.health > 0:
			var knock_dir := signi(dir)
			if knock_dir == 0:
				knock_dir = 1

			is_hurt = true
			hurt_timer = hurt_duration

			# --- FIX 1: Clamp power so it NEVER becomes crazy ---
			var k_power := clampf(power, 200, 800)

			# --- FIX 2: Apply strong knockback instantly (frame perfect) ---
			velocity = Vector2(knock_dir * k_power, -k_power * 0.15)

			anim.play("Hurt")
			shake_camera(0.25, 18)

			# --- FIX 3: Small freeze frame for impact ---
			await pause_brief(0.15, 0.1)

			# --- FIX 4: DO NOT cancel velocity here ---
			# Do NOT reset velocity.x = 0  (this kills knockback)
			can_hurt = false
			start_invincibility()



# CAMERA SHAKE (unchanged)
func shake_camera(duration: float = 0.5, magnitude: float = 8.0) -> void:
	var original_mode = cam.process_mode
	cam.process_mode = Node.PROCESS_MODE_ALWAYS

	var original_pos = cam.position
	var timer = 0.0

	while timer < duration:
		cam.position = original_pos + Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
		await get_tree().process_frame
		timer += 0.016

	cam.position = original_pos
	cam.process_mode = original_mode


var _is_time_scaled := false


func pause_brief(duration: float, slow: float = 0.1) -> void:
	if _is_time_scaled:
		return
	_is_time_scaled = true

	var original_time := Engine.time_scale
	Engine.time_scale = slow

	var start_ms := Time.get_ticks_msec()
	var target_ms := start_ms + int(duration * 1000.0)

	while Time.get_ticks_msec() < target_ms:
		await get_tree().process_frame

	Engine.time_scale = original_time
	_is_time_scaled = false


# -----------------------------------------------------
# INVINCIBILITY FLASH
# -----------------------------------------------------
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
