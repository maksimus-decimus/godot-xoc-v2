extends Node

@onready var start_button = $CanvasLayer/CenterContainer/VBoxContainer/StartButton

func _ready() -> void:
	start_button.grab_focus()
	Global.selected_map = 0

func _on_start_button_pressed() -> void:
	SceneTransition.loading_screen_to_scene("res://scenes/game.tscn")
