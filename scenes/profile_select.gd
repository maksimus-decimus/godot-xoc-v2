extends Control

@onready var profiles_list = $VBoxContainer/ProfilesScroll/ProfilesList
@onready var new_profile_input = $VBoxContainer/CreateSection/NewProfileInput
@onready var create_button = $VBoxContainer/CreateSection/CreateButton
@onready var back_button = $VBoxContainer/BackButton

var profile_buttons = []

func _ready() -> void:
	create_button.pressed.connect(_on_create_profile_pressed)
	back_button.pressed.connect(_on_back_pressed)
	new_profile_input.text_submitted.connect(func(_text): _on_create_profile_pressed())
	
	# Cargar lista de perfiles
	await get_tree().process_frame
	
	# Si hay un perfil activo, opción para continuar directamente
	if not UserProfile.current_profile_name.is_empty():
		var continue_label = Label.new()
		continue_label.text = "Perfil actual: %s" % UserProfile.current_profile_name
		continue_label.add_theme_font_size_override("font_size", 14)
		continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		profiles_list.add_child(continue_label)
		
		var continue_btn = Button.new()
		continue_btn.text = "Continuar con %s" % UserProfile.current_profile_name
		continue_btn.custom_minimum_size = Vector2(0, 50)
		continue_btn.pressed.connect(func(): _on_profile_selected(UserProfile.current_profile_name))
		profiles_list.add_child(continue_btn)
		profile_buttons.append(continue_btn)
		
		var sep = HSeparator.new()
		profiles_list.add_child(sep)
	
	refresh_profile_list()
	
	if profile_buttons.size() > 0:
		profile_buttons[0].grab_focus()
	else:
		create_button.grab_focus()

func refresh_profile_list() -> void:
	# Limpiar lista anterior
	for button in profile_buttons:
		button.queue_free()
	profile_buttons.clear()
	
	# Obtener perfiles disponibles
	var profiles = UserProfile.get_all_profiles()
	
	if profiles.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No hay perfiles creados"
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		profiles_list.add_child(empty_label)
	else:
		# Crear botón para cada perfil
		for profile_name in profiles:
			var hbox = HBoxContainer.new()
			hbox.custom_minimum_size = Vector2(0, 50)
			hbox.add_theme_constant_override("separation", 10)
			
			# Botón para seleccionar perfil
			var select_btn = Button.new()
			select_btn.text = profile_name
			select_btn.custom_minimum_size = Vector2(200, 40)
			select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			select_btn.pressed.connect(func(): _on_profile_selected(profile_name))
			hbox.add_child(select_btn)
			profile_buttons.append(select_btn)
			
			# Botón para eliminar perfil
			var delete_btn = Button.new()
			delete_btn.text = "🗑️ Eliminar"
			delete_btn.custom_minimum_size = Vector2(100, 40)
			delete_btn.pressed.connect(func(): _on_delete_profile(profile_name))
			hbox.add_child(delete_btn)
			
			profiles_list.add_child(hbox)

func _on_profile_selected(profile_name: String) -> void:
	if UserProfile.load_profile(profile_name):
		print("✓ Perfil seleccionado: ", profile_name)
		SceneTransition.fade_to_scene("res://scenes/profile_menu.tscn")
	else:
		print("❌ Error al cargar perfil")

func _on_create_profile_pressed() -> void:
	var profile_name = new_profile_input.text.strip_edges()
	
	if profile_name.is_empty():
		print("❌ El nombre no puede estar vacío")
		return
	
	if UserProfile.create_profile(profile_name):
		print("✓ Perfil creado: ", profile_name)
		new_profile_input.text = ""
		refresh_profile_list()
	else:
		print("❌ Error al crear perfil")

func _on_delete_profile(profile_name: String) -> void:
	# Confirmación
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Eliminar Perfil"
	confirm_dialog.dialog_text = "¿Estás seguro de que deseas eliminar '%s'?" % profile_name
	
	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(func():
		if UserProfile.delete_profile(profile_name):
			print("✓ Perfil eliminado: ", profile_name)
			refresh_profile_list()
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.cancelled.connect(func():
		confirm_dialog.queue_free()
	)
	
	confirm_dialog.popup_centered_ratio(0.4)

func _on_back_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/main_menu.tscn")
