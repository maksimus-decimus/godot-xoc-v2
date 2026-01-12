extends Control

@onready var name_input = $PanelContainer/VBoxContainer/NameInput
@onready var wins_label = $PanelContainer/VBoxContainer/StatsVBox/WinsLabel
@onready var losses_label = $PanelContainer/VBoxContainer/StatsVBox/LossesLabel
@onready var win_rate_label = $PanelContainer/VBoxContainer/StatsVBox/WinRateLabel
@onready var main_char_label = $PanelContainer/VBoxContainer/StatsVBox/MainCharLabel
@onready var total_games_label = $PanelContainer/VBoxContainer/StatsVBox/TotalGamesLabel
@onready var save_button = $PanelContainer/VBoxContainer/HBoxContainer/SaveButton
@onready var delete_button = $PanelContainer/VBoxContainer/HBoxContainer/DeleteButton
@onready var back_button = $PanelContainer/VBoxContainer/HBoxContainer/BackButton

func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Esperar a que UserProfile esté listo
	await get_tree().process_frame
	
	update_display()
	
	# Si no hay perfil activo, muestra mensaje
	if UserProfile.current_profile_name.is_empty():
		name_input.placeholder_text = "No hay perfil activo"
		name_input.editable = false
		save_button.disabled = true
		delete_button.disabled = true
	else:
		name_input.editable = true
		delete_button.disabled = false

func update_display() -> void:
	if not UserProfile.current_profile_name.is_empty():
		var profile = UserProfile.current_profile
		name_input.text = profile.get("name", "")
		
		wins_label.text = "Victorias: %d" % profile.get("wins", 0)
		losses_label.text = "Derrotas: %d" % profile.get("losses", 0)
		total_games_label.text = "Partidas totales: %d" % UserProfile.get_total_games()
		
		var win_rate = UserProfile.get_win_rate()
		win_rate_label.text = "Tasa de victoria: %.1f%%" % win_rate
		
		var char_name = "Quixote" if profile.get("main_character", 0) == 0 else "Ishmael"
		main_char_label.text = "Personaje favorito: %s" % char_name
	else:
		wins_label.text = "Victorias: 0"
		losses_label.text = "Derrotas: 0"
		total_games_label.text = "Partidas totales: 0"
		win_rate_label.text = "Tasa de victoria: 0.0%"
		main_char_label.text = "Personaje favorito: Quixote"

func _on_save_pressed() -> void:
	if UserProfile.current_profile_name.is_empty():
		print("❌ No hay perfil seleccionado")
		return
	
	UserProfile.save_profile()
	update_display()
	print("✓ Perfil actualizado")

func _on_delete_pressed() -> void:
	if UserProfile.current_profile_name.is_empty():
		print("❌ No hay perfil para eliminar")
		return
	
	# Confirmación
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Eliminar Perfil"
	confirm_dialog.dialog_text = "¿Estás seguro de que deseas eliminar '%s'?" % UserProfile.current_profile_name
	
	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(func():
		var profile_name = UserProfile.current_profile_name
		if UserProfile.delete_profile(profile_name):
			print("✓ Perfil eliminado")
			name_input.text = ""
			delete_button.disabled = true
			update_display()
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.cancelled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered_ratio(0.4)

func _on_back_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/main_menu.tscn")
