extends CharacterBody2D

# -----------------------------
#       EXPORT VARIABLES
# -----------------------------
@export var speed: float = 300
@export var attack_cooldown: float = 3
@export var gravity: float = 1200
@export var attack_position: float = 10

# -----------------------------
#       INTERNAL VARIABLES
# -----------------------------
var health = 100
var spawn: bool = false
var alive: bool = false
var player_area: Area2D = null
var in_atk_radius: bool = false
var can_attack: bool = true

# -----------------------------
#       NODE REFERENCES
# -----------------------------
@onready var anim = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var chase_area = $Chase
@onready var detect_area = $PlayerDetect
@onready var attack_area = $AttackRadius
@onready var hitbox_area = $Hitbox
@export var energy_fragment_scene: PackedScene 
var spawned = false
var has_dropped = false

# -----------------------------
#       READY
# -----------------------------


# -----------------------------
#       PHYSICS PROCESS
# -----------------------------
func _physics_process(delta: float) -> void:
	if health <= 0:	
		anim.play('Death')
		if has_dropped:
			return
		has_dropped = true
		var fragment = energy_fragment_scene.instantiate()
		fragment.global_position = global_position
		# Add fragment to the same parent as the skeleton
		get_parent().add_child(fragment)
		await anim.animation_finished
		self.queue_free()
		return
		
	if not spawn:
		velocity = Vector2.ZERO
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Chase player if alive
	if player_area and alive:
		var player_distance = (player_area.get_parent().global_position - global_position)
		var dir = player_distance.normalized()

		# Flip sprite and attack area
		if dir.x > 0:
			sprite.flip_h = false
			attack_area.position.x = attack_position
		else:
			sprite.flip_h = true
			attack_area.position.x = attack_position - 150

		# Move towards player if far
		if abs(player_distance.x) >= 75:
			velocity.x = dir.x * speed
			if anim.current_animation not in ['Attack', 'Spawn' , 'Damage' , 'Death']:
				anim.play("Walk")
		else:
			velocity.x = 0
			if anim.current_animation not in ['Attack', 'Spawn' , 'Damage' , 'Death']:
				anim.play("Idle")
		for area in attack_area.get_overlapping_areas():
			if area.is_in_group('PlayerHitbox'):
				if can_attack and anim.current_animation not in ['Damage' , 'Death']:
					anim.play('Attack')
		
	else:
		velocity = Vector2.ZERO
		if alive and anim.current_animation not in ['Attack', 'Spawn' , 'Damage' , 'Death']:
			anim.play("Idle")
		elif not alive:
			anim.play("Nothing")
			
	
	

	move_and_slide()

# -----------------------------
#       SPAWN
# -----------------------------

func spawn_skeleton():
	anim.play("Spawn")

	# Connect signals
	chase_area.area_entered.connect(_on_chase_entered)
	chase_area.area_exited.connect(_on_chase_exited)
	detect_area.area_exited.connect(_on_detect_exited)
	hitbox_area.area_entered.connect(_on_hitbox_entered)
	
		# Manually check if player is already inside
	for area in chase_area.get_overlapping_areas():
		if area.is_in_group("PlayerHitbox"):
			_on_chase_entered(area)
			
	for area in chase_area.get_overlapping_areas():
		if area.is_in_group('PlayerHitbox'):
			can_attack = true
# -----------------------------
#       CHASE AREA
# -----------------------------
func _on_chase_entered(area: Area2D):
	if area.is_in_group("PlayerHitbox"):
		player_area = area

func _on_chase_exited(area: Area2D):
	if area == player_area:
		player_area = null

# -----------------------------
#       DETECT AREA
# -----------------------------

func _on_detect_exited(area: Area2D):
	if area.is_in_group("PlayerHitbox"):
		if alive and anim.current_animation not in ['Attack', 'Spawn' , 'Damage' , 'Death']:
			anim.play("Walk")

# -----------------------------
#       ATTACK AREA
# -----------------------------

# -----------------------------
#       HITBOX DAMAGE (on touch)
# -----------------------------
func _on_hitbox_entered(area: Area2D):
	if area.is_in_group("PlayerHitbox"):
		area.get_parent().take_damage(10, area.get_parent().global_position.x - global_position.x, 500)

# -----------------------------
#       ATTACK COOLDOWN & DAMAGE
# -----------------------------
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Spawn":
		alive = true
		spawn = true
		anim.play("Idle")

	elif anim_name == "Attack":
		# Apply damage if player still in attack area
		for area in attack_area.get_overlapping_areas():
			if area.is_in_group("PlayerHitbox"):
				area.get_parent().take_damage(10, area.get_parent().global_position.x - global_position.x, 1500)

		# Start cooldown
		get_tree().create_timer(attack_cooldown).connect("timeout", Callable(self, "_reset_attack"))
	
		
		
func _reset_attack():
	can_attack = true
	# If player still in attack range, immediately attack again
	print(in_atk_radius)
	if in_atk_radius:
		anim.play("Attack")
		can_attack = false


func _on_spawn_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerHitbox"):
		if not spawned:
			spawn_skeleton()
			spawned = true

func take_damage(amount):
	self.health -= amount
	anim.play('Damage')
	print(self.health)
