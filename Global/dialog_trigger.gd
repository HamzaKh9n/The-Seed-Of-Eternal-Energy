extends Area2D

@export var dialog : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerHitbox"):
		var dialog_box = get_tree().get_first_node_in_group("DialogBox")
		if dialog:
			dialog_box.enqueue(dialog)
		queue_free()
