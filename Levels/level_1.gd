extends Node2D

var paused := false
var dialog_shown = false
var encounter_dialog_shown = false
var portal_dialog_shown = false
var portal_interactions = 0

func _ready() -> void:
	Engine.time_scale = 1.2
	Global.Level = 1
	Global.max_frags = 10
	
func _process(_delta: float) -> void:

	# -------------------------
	# ENCOUNTER DIALOG
	# -------------------------
	if Global.encounters == 1 and not encounter_dialog_shown:
		encounter_dialog_shown = true   # SET FIRST
		await $DialogBox.show_dialog("The Enemies also drop Energy Fragments. Slay them if you can't find enough.")

	# -------------------------
	# FIRST FRAGMENT DIALOG
	# -------------------------
	if Global.frags == 1 and not dialog_shown:
		dialog_shown = true   # SET FIRST
		await $DialogBox.show_dialog("After collecting an Energy Fragment, 20% of your health is healed.")

	# -------------------------
	# ALL FRAGS DIALOG
	# -------------------------
	if Global.frags == 2 and not portal_dialog_shown:
		portal_dialog_shown = true   # SET FIRST
		await $DialogBox.show_dialog(
            "After collecting all Energy Fragments, find the portal for the next area."
		)

		
		


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	paused = !paused
	get_tree().paused = paused

	$"Pause menu".visible = paused


	
func _on_resume_pressed() -> void:
	print("resume")
	toggle_pause()


#
func _on_quit_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://Title/title.tscn")


func _on_tp_area_entered(area: Area2D) -> void:
	if area.is_in_group('PlayerHitbox'):
		if Global.frags >= 10:
			await $DialogBox.show_dialog("Congratulations !! You Found the Portal.")
			get_tree().change_scene_to_file("res://Levels/level_2.tscn")
		else:
			if portal_interactions >= 1:
				await $DialogBox.show_dialog("Not Enough Energy Fragments")
			else:
				await $DialogBox.show_dialog("Congratulations !! You Found the Portal || Collect Enough Energy frags to Pass Through It.")
		portal_interactions += 1
