extends CanvasLayer

@onready var tex = $TextureRect
var speed = 50

func _process(delta):
	tex.position.x -= speed * delta
	if tex.position.x <= -tex.texture.get_width():
		tex.position.x = 0
