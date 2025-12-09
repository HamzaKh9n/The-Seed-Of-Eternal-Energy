extends CharacterBody2D

# -----------------------------------------------------
# MOVEMENT VARIABLES
# -----------------------------------------------------
@export var move_speed := 600.0
@export var acceleration := 30.0
@export var deceleration := 25.0
@export var jump_force := -900.0
@export var gravity := 3000.0

@export var low_gravity := 1000.0
@export var high_gravity := 3000.0

@onready var cam = $Camera2D
@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var attack_radius = $AttackRadius
@onready var fixed_scale = scale.x

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


func _ready() -> void:
	anim.play("Idle")


func _physics_process(delta: float) -> void:
	# Prevent double gravity application
	var applied_gravity := false

	if Global.stop:
		anim.play("Idle")
		velocity.x = 0
		if not is_on_floor():
			if not applied_gravity:
				velocity.y += gravity * delta
				applied_gravity = true
		move_and_slide()
		return
		
	# PLAYER DEATH
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
				await Global.safe_frame()
				tree.change_scene_to_file("res://Levels/level_1.tscn")
			2:
				await Global.safe_frame()
				tree.change_scene_to_file("res://Levels/level_2.tscn")

			3:
				await Global.safe_frame()
				tree.change_scene_to_file("res://Emperor's Grave Scenes/graves.tscn")
		return

	# HURT STATE
	if is_hurt:
		hurt_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, 6.0 * delta)

		if not applied_gravity:
			velocity.y += gravity * delta
			applied_gravity = true

		if hurt_timer <= 0:
			is_hurt = false

		move_and_slide()
		return

	# HORIZONTAL MOVEMENT
	var dir_right := 1 if Input.is_action_pressed("D") else 0
	var dir_left := 1 if Input.is_action_pressed("A") else 0
	var direction := dir_right - dir_left

	if direction != 0 and not attack:
		sprite.flip_h = direction < 0

	if not attack:
		if direction != 0:
			velocity.x = lerp(velocity.x, direction * move_speed, acceleration * delta)
			if is_on_floor() and anim.current_animation not in ["Land"]:
				move_speed = 600
				anim.play("Run")
		else:
			# Avoid jitter while airborne
			if is_on_floor():
				move_speed = 600
				velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
			if is_on_floor() and anim.current_animation not in ["Land", "Jump", "Death"]:
				anim.play("Idle")

	# JUMP INPUT
	if is_on_floor() and Input.is_action_just_pressed("Space") and not attack:
		$JumpBreath.play()
		anim.play("Jump")
		velocity.y = jump_force

	# SMOOTHER GRAVITY HANDLING + AIR CONTROL FIX
	if not is_on_floor():

		# -------------------------------
		# ⭐ AIR MOVEMENT FIX ⭐
		# Only move in air when A/D is held.
		# If released, drop straight down.
		# -------------------------------
		var air_dir := Input.get_action_strength("D") - Input.get_action_strength("A")

		if air_dir != 0:
			velocity.x = lerp(velocity.x, air_dir * (move_speed * 0.6), 8 * delta)
		else:
			velocity.x = lerp(velocity.x, 0.0, 12 * delta)
		# -------------------------------

		if velocity.y < 0:
			var g = low_gravity if Input.is_action_pressed("Space") else high_gravity
			if not applied_gravity:
				velocity.y += g * delta
				applied_gravity = true
		else:
			if not applied_gravity:
				velocity.y += gravity * delta
				applied_gravity = true

	# ANIM WHILE AIRBORNE
	if not is_on_floor() and not attack:
		if velocity.y > 0:
			anim.play("Fall")
		elif velocity.y < 0:
			anim.play("Jump")

	# LAND ANIMATION
	if not was_on_floor and is_on_floor() and velocity.y >= 0:
		if anim.current_animation not in ["Jump", "Fall", "Hurt"]:
			anim.play("Land")

	was_on_floor = is_on_floor()

	# ATTACK INPUT
	if Input.is_action_just_pressed("Attack") and not cooldown:
		attack = true
		cooldown = true

		$"Attack Cooldown".start()
		$"Combo Cooldown".start()
		velocity.x = 0

		match combo:
			0:
				anim.play("Attack 1")
			1:
				anim.play("Attack 2")
			2:
				anim.play("Attack 3")

		combo += 1
		if combo > 2:
			combo = 0

	move_and_slide()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Land":
		anim.play("Idle")

	if anim_name.begins_with("Attack"):
		attack = false
		Do_attack()
		

func Do_attack():
	for area in attack_radius.get_overlapping_areas():
		if area.is_in_group("EnemyHitbox"):
			var enemy = area.get_parent()
			enemy.take_damage(Global.Power)
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
