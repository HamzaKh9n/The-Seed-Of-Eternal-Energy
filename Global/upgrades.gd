extends CanvasLayer

@onready var c1 = $HBoxContainer/VBoxContainer/Choice1
@onready var c2 = $HBoxContainer2/VBoxContainer/Choice2
@onready var c3 = $HBoxContainer3/VBoxContainer/Choice3
@onready var messagebox = preload("res://Global/messages.tscn")
var c1Task = null
var c2Task = null
var c3Task = null
var message = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$".".visible = false


func create_upgrades(x=[] , y=[] , z=[]):
	c1.text = x[0] + "\n" + x[1]
	c1Task = x[2]
	c2.text = y[0] + "\n" + y[1]
	c2Task = y[2]
	c3.text = z[0] + "\n" + z[1]
	c3Task = z[2]
	message = messagebox.instantiate()
	add_child(message)
	message.show_message("Select An Unpgrade")
	$".".visible = true
	Global.stop = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_choice_1_pressed() -> void:
	Global.upgrade = c1Task
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$".".visible = false
	message.hide_message()
	
	
func _on_choice_2_pressed() -> void:
	Global.upgrade = c2Task
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$".".visible = false
	message.hide_message()
	
	
func _on_choice_3_pressed() -> void:
	Global.upgrade = c3Task
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$".".visible = false
	message.hide_message()
	
