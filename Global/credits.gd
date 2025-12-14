extends Node2D

@onready var slides := [
	$CanvasLayer/Sprite2D,
	$CanvasLayer/Sprite2D2,
	$CanvasLayer/Sprite2D3,
	$CanvasLayer/Sprite2D4,
	$CanvasLayer/Sprite2D5
]

@onready var fade_rect := $FadeIn/ColorRect

var fade_time := 1.5
var wait_time := 2.0
var running := false   # prevents double execution when instantiated


func _ready():
	if running:
		return

	running = true

	# Hide all slides initially
	for slide in slides:
		slide.visible = false
		slide.modulate.a = 0.0

	fade_rect.modulate.a = 1.0   # screen starts black

	await fade_from_black()
	await play_credits()

	# Fade to black and leave
	await fade_to_black()

	SaveGame.reset_game()
	queue_free()
	get_tree().change_scene_to_file("res://Global/game_title.tscn")
	


# -----------------------------------------------------------
# MAIN CREDIT SEQUENCE
# -----------------------------------------------------------
func play_credits() -> void:
	for slide in slides:

		# Show this slide
		slide.visible = true
		
		# Fade it in
		await fade_in_slide(slide)

		# Wait on screen
		await get_tree().create_timer(wait_time).timeout

		# Fade it out
		await fade_out_slide(slide)

		# Hide before moving to next slide
		slide.visible = false



# -----------------------------------------------------------
# FADE HELPERS
# -----------------------------------------------------------
func fade_from_black() -> void:
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 0.0, fade_time)
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	await t.finished


func fade_to_black() -> void:
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	await t.finished



# -----------------------------------------------------------
# SLIDE FADES
# -----------------------------------------------------------
func fade_in_slide(slide: Sprite2D) -> void:
	slide.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(slide, "modulate:a", 1.0, fade_time)
	await t.finished


func fade_out_slide(slide: Sprite2D) -> void:
	var t = create_tween()
	t.tween_property(slide, "modulate:a", 0.0, fade_time)
	await t.finished



# -----------------------------------------------------------
# OPTIONAL: Stop Credits Early (never used unless you want)
# -----------------------------------------------------------
func stop_credits():
	queue_free()
