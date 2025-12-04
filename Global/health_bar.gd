extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TextureProgressBar.value = Global.health
	$TextureProgressBar2.max_value = Global.max_frags
	$TextureProgressBar2.value = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TextureProgressBar.value = Global.health
	$TextureProgressBar2.value = Global.frags
	
