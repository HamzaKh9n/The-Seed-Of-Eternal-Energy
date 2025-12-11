extends Area2D

@export var X : float
@export var Y : float
var damageState = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var areas = $".".get_overlapping_areas()
	for i in areas:
		if i.is_in_group("PlayerHitbox"):
			if not damageState:
				damageState = true
				Global.stop = true
				var dir = 0
				if i.get_parent().get_child(0).flip_h:
					dir = 1
				else:
					dir = -1
				await i.get_parent().take_damage(25 , dir , 1000)
				print('Got Damage')
				Global.stop = false
				i.get_parent().global_position.x =  X
				i.get_parent().global_position.y =  Y
				damageState = false
			
		if i.is_in_group("EnemyHitbox"):
			i.get_parent().take_damage(100)
