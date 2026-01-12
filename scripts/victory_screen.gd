extends Node

@onready var winner_label = $CanvasLayer/CenterContainer/VBoxContainer/WinnerLabel
@onready var menu_button = $CanvasLayer/CenterContainer/VBoxContainer/MenuButton

func _ready() -> void:
	winner_label.text = "¡JUGADOR %d GANA!" % Global.winner
	menu_button.grab_focus()
	
	# Guardar estadísticas del perfil
	_update_profile_stats()

func _update_profile_stats() -> void:
	if UserProfile.current_profile_name.is_empty():
		return
	
	# El perfil del jugador 1 gana/pierde
	var player1_character = Global.player1_character
	var player_won = Global.winner == 1
	
	UserProfile.update_stats(player_won, player1_character)

func _on_menu_button_pressed() -> void:
	Global.reset_game()
	SceneTransition.fade_to_scene("res://scenes/main_menu.tscn")
