extends Node

@onready var p1_char1_button = $CanvasLayer/HBoxContainer/P1Panel/VBoxContainer/Char1Button
@onready var p1_char2_button = $CanvasLayer/HBoxContainer/P1Panel/VBoxContainer/Char2Button
@onready var p2_char1_button = $CanvasLayer/HBoxContainer/P2Panel/VBoxContainer/Char1Button
@onready var p2_char2_button = $CanvasLayer/HBoxContainer/P2Panel/VBoxContainer/Char2Button
@onready var continue_button = $CanvasLayer/ContinueButton
@onready var p1_label = $CanvasLayer/HBoxContainer/P1Panel/VBoxContainer/P1Label
@onready var p2_label = $CanvasLayer/HBoxContainer/P2Panel/VBoxContainer/P2Label

var p1_selected: bool = false
var p2_selected: bool = false
var p1_character: int = -1
var p2_character: int = -1

func _ready() -> void:
	MusicManager.play_music(MusicManager.CHAR_SELECT_MUSIC)
	continue_button.disabled = true
	update_ui()

func _input(event: InputEvent) -> void:
	# Jugador 1 selecciona
	if event.is_action_pressed("p1_up") or event.is_action_pressed("p1_down"):
		if not p1_selected:
			p1_character = 0 if p1_character != 0 else 1
			update_ui()
	
	if event.is_action_pressed("p1_hit"):
		if not p1_selected and p1_character != -1:
			p1_selected = true
			update_ui()
	
	# Jugador 2 selecciona
	if event.is_action_pressed("p2_up") or event.is_action_pressed("p2_down"):
		if not p2_selected:
			p2_character = 0 if p2_character != 0 else 1
			update_ui()
	
	if event.is_action_pressed("p2_hit"):
		if not p2_selected and p2_character != -1:
			p2_selected = true
			update_ui()

func update_ui() -> void:
	# Actualizar indicadores de P1
	p1_char1_button.modulate = Color.WHITE if p1_character != 0 else Color.YELLOW
	p1_char2_button.modulate = Color.WHITE if p1_character != 1 else Color.YELLOW
	
	if p1_selected:
		p1_label.text = "JUGADOR 1: ¡LISTO!"
		p1_label.modulate = Color.GREEN
	else:
		p1_label.text = "JUGADOR 1: Selecciona"
		p1_label.modulate = Color.WHITE
	
	# Actualizar indicadores de P2
	p2_char1_button.modulate = Color.WHITE if p2_character != 0 else Color.YELLOW
	p2_char2_button.modulate = Color.WHITE if p2_character != 1 else Color.YELLOW
	
	if p2_selected:
		p2_label.text = "JUGADOR 2: ¡LISTO!"
		p2_label.modulate = Color.GREEN
	else:
		p2_label.text = "JUGADOR 2: Selecciona"
		p2_label.modulate = Color.WHITE
	
	# Habilitar botón continuar
	continue_button.disabled = not (p1_selected and p2_selected)

func _on_continue_button_pressed() -> void:
	Global.player1_character = p1_character
	Global.player2_character = p2_character
	
	# Guardar perfil del jugador 1
	UserProfile.current_profile["main_character"] = p1_character
	UserProfile.save_profile()
	UserProfile.save_last_profile()
	
	SceneTransition.fade_to_scene("res://scenes/map_select.tscn")
