extends Area2D

@export var energy_amount: int = 1
@export var speed: float = 300
@export var magnet_range: float = 150
@onready var sprite: Sprite2D = $Sprite2D

var player_hitbox: Area2D = null
var collected: bool = false
var pulse_time: float = 0.0

func _ready():
	# Connect the area_entered signal correctly
	area_entered.connect(Callable(self, "_on_area_entered"))

func _process(delta):
	# Glow pulse
	pulse_time += delta * 3
	var glow = 0.6 + 0.4 * sin(pulse_time)
	sprite.modulate.a = glow
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
			Global.health += 20
			if Global.health > 100:
				Global.health = 100
			print(Global.frags)

func _on_area_entered(area: Area2D):
	# Only trigger for player hitbox
	if area.is_in_group("PlayerHitbox"):
		player_hitbox = area
		collected = false
