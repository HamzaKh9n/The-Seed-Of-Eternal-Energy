extends CanvasLayer

@onready var label = $VBoxContainer/RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$".".visible = false
	$VBoxContainer/RichTextLabel.modulate.a = 0

func show_message(text , duration = 1  , auto_hide = false):
	#var tween = create_tween()
	#tween.tween_property($VBoxContainer/RichTextLabel , "modulate.a" , 1 , 0.4)
	#tween.set_trans(Tween.TRANS_SINE)
	#tween.set_ease(Tween.EASE_IN_OUT)
	#tween.tween_callback(func():		
		#print("Message Shown" , $VBoxContainer/RichTextLabel)
		#$VBoxContainer/RichTextLabel.modulate.a = 1
	#)
	label.modulate.a = 0
	var t := 0.0
	$VBoxContainer/RichTextLabel.text = text
	while t < duration:
		t += get_process_delta_time()
		label.modulate.a = t / duration
		await Global.safe_frame()
	label.modulate.a = 1
	
	if auto_hide:
		t = 0
		while t < 3:
			t += get_process_delta_time()
			await Global.safe_frame()
		hide_message()
	
func hide_message():
	label.modulate.a = 0
	queue_free()
	
	
