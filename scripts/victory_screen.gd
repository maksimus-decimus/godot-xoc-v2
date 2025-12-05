extends Node

@onready var winner_label = $CanvasLayer/CenterContainer/VBoxContainer/WinnerLabel
@onready var menu_button = $CanvasLayer/CenterContainer/VBoxContainer/MenuButton

func _ready() -> void:
	winner_label.text = "¡JUGADOR %d GANA!" % Global.winner
	menu_button.grab_focus()

func _on_menu_button_pressed() -> void:
	Global.reset_game()
	SceneTransition.fade_to_scene("res://scenes/main_menu.tscn")
