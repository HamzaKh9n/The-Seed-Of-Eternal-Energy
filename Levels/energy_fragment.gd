extends Area2D

@export var energy_amount: int = 1
@export var speed: float = 300
@export var magnet_range: float = 150
@onready var sprite: Sprite2D = $Sprite2D
@export var special : String = ''

var player_hitbox: Area2D = null
var collected: bool = false
var pulse_time: float = 0.0

func _ready():
	# Connect the area_entered signal correctly
	area_entered.connect(Callable(self, "_on_area_entered"))

func _process(delta):
	if special == 'eternal':
		modulate = Color(2.115, 1.806, 0.0, 0.804)
	if special == 'dash':
		modulate = Color(1.0, 0.0, 0.0, 1.0)
	elif special == 'knockback':
		modulate = Color(0.713, 0.321, 0.98, 1.0)
	elif special == 'heal':
		modulate = Color(0.0, 6.773, 0.0, 1.0)
	elif special == 'lifesteal':
		modulate = Color(0.423, 0.218, 0.656, 1.0)
	# Glow pulse
	pulse_time += delta * 3
	var glow = 0.6 + 0.4 * sin(pulse_time)
	sprite.modulate.a = glow
	if special == 'eternal':
		sprite.scale = Vector2.ONE * (0.1 + 0.2 * sin(pulse_time))
	else:
		sprite.scale = Vector2.ONE * (0.1 + 0.2 * sin(pulse_time))
	# Magnet effect toward player if detected
	if player_hitbox and not collected:
		var dir = (player_hitbox.get_parent().global_position - global_position)
		var dist = dir.length()
		if dist < magnet_range:
			global_position += dir.normalized() * speed * delta
		# Collect if very close
		
		if dist < 20:
			if player_hitbox.get_parent().has_method("add_energy"):
				player_hitbox.get_parent().add_energy(energy_amount)
				
			queue_free()
			collected = true
			Global.frags += 1
			if Global.heal:
				Global.health += 20
				if Global.health > 100:
					Global.health = 100
			print(Global.frags)
		var dialog = get_tree().get_first_node_in_group("DialogBox")
		if not special == '':
			if special == 'dash':
				Global.give_powerup('dash')
				await dialog.enqueue("Congratulation!! You Found Dash Ability Orb. [Q] for Dash")
				special = ''
			elif special == 'heal':
				Global.give_powerup('heal')
				await dialog.enqueue("Congratulation!! You Found Heal Ability Orb. Collect Energy to Heal 20% of Your Health")
				special = ''
			elif special == 'stun':
				Global.give_powerup('stun')
				await dialog.enqueue("Congratulation!! You Found Stun Ability Orb. Hitting Enimies Stun them fo 0.5 second")
				special = ''
			elif special == 'knockback':
				Global.give_powerup('knockback')	
				await dialog.enqueue("Congratulation!! You Found Knockback Ability Orb. Hitting Enimies Knocks them Backwards")
				special = ''
			elif special == 'lifesteal':
				Global.give_powerup('lifesteal')	
				await dialog.enqueue("Congratulation!! You Found Lifesteal Ability Orb. Hitting Enimies Recovers 10HP!!")
				special = ''


func _on_area_entered(area: Area2D):
	# Only trigger for player hitbox
	if area.is_in_group("PlayerHitbox"):
		player_hitbox = area
		collected = false
