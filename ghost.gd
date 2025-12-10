extends Node2D

func _ready() -> void:
	ghosting()

func set_property(tx_pos , tx_scale):
	position = tx_pos
	scale = tx_scale
	
func ghosting():
	var tween_fade = get_tree().create_tween()
	tween_fade.tween_property(self, "self_modulate" , Color(0 , 0 , 0 , 0) , 0.1)
	await tween_fade.finished
	queue_free()
