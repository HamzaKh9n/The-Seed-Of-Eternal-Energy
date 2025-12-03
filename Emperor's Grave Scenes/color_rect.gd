extends ColorRect

@export var pulse_strength: float = 0.03
@export var pulse_speed: float = 2.0
var base_color: Color

func _ready():
	base_color = color

func _process(delta):
	var pulse = sin(Time.get_ticks_msec() / 1000.0 * pulse_speed) * pulse_strength
	color = Color(base_color.r, base_color.g, base_color.b, base_color.a + pulse)
