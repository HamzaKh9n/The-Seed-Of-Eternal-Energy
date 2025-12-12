extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var player := get_tree().get_first_node_in_group("player")

@export var follow_speed := 150.0
@export var dash_speed := 450.0
@export var follow_distance := 120.0   # when reached, dash straight
@export var life_time := 7.0           # auto delete failsafe

var direction := Vector2.ZERO
var dashing := false

func _ready():
	# Kill on timeout
	var timer := get_tree().create_timer(life_time)
	timer.timeout.connect(die)
	sprite.play('Appear')

	# Hit player logic
	hitbox.area_entered.connect(_on_hitbox_entered)

func die():
	sprite.play("Death")
	await get_tree().create_timer(2).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if player == null:
		queue_free()
		return

	if not dashing:
		_follow_player(delta)
	else:
		_dash_forward(delta)

	move_and_slide()


# -------------------------
# FOLLOW PLAYER PHASE
# -------------------------
func _follow_player(delta: float):
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	sprite.play('Idle')
	# reach dash distance
	if dist <= follow_distance:
		dashing = true
		direction = to_player.normalized()
		return

	# move while following
	direction = to_player.normalized()
	velocity = direction * follow_speed

	# flip sprite
	sprite.flip_h = direction.x < 0


# -------------------------
# DASH PHASE
# -------------------------
func _dash_forward(delta: float):
	velocity = direction * dash_speed
	

	# if hits wall or floor → die
	if is_on_wall() or is_on_floor():
		sprite.play("Death")
		await get_tree().create_timer(2).timeout
		queue_free()


# -------------------------
# HIT PLAYER
# -------------------------
func _on_hitbox_entered(area):
	if area.is_in_group("PlayerHitbox"):
		var player_node = area.get_parent()
		if player_node and player_node.has_method("take_damage"):
			# deal damage
			player_node.take_damage(10, player_node.global_position.x - global_position.x, 500)
		sprite.play("Death")
		await get_tree().create_timer(2).timeout
		queue_free()
