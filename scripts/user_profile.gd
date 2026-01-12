extends Node

const PROFILES_DIR = "user://profiles/"
const LAST_PROFILE_FILE = "user://last_profile.txt"

var current_profile: Dictionary = {
	"name": "",
	"main_character": 0,
	"wins": 0,
	"losses": 0,
	"created_at": "",
	"updated_at": ""
}

var current_profile_name: String = ""

func _ready() -> void:
	# Crear directorio de perfiles si no existe
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_absolute(PROFILES_DIR)
		print("✓ Directorio de perfiles creado")
	
	# Cargar último perfil usado
	load_last_profile()

func get_all_profiles() -> PackedStringArray:
	"""Retorna lista de todos los perfiles disponibles"""
	var profiles = PackedStringArray()
	
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		return profiles
	
	var dir = DirAccess.open(PROFILES_DIR)
	if dir == null:
		print("❌ Error al abrir directorio de perfiles")
		return profiles
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			# Remover .json del nombre
			var profile_name = file_name.trim_suffix(".json")
			profiles.append(profile_name)
		file_name = dir.get_next()
	
	return profiles

func profile_exists(profile_name: String) -> bool:
	var profile_path = PROFILES_DIR + profile_name + ".json"
	return FileAccess.file_exists(profile_path)

func create_profile(profile_name: String) -> bool:
	if profile_name.is_empty():
		print("❌ El nombre no puede estar vacío")
		return false
	
	# Verificar que no exista ya
	if profile_exists(profile_name):
		print("❌ Ya existe un perfil con ese nombre")
		return false
	
	# Crear nuevo perfil
	current_profile = {
		"name": profile_name,
		"main_character": 0,
		"wins": 0,
		"losses": 0,
		"created_at": Time.get_datetime_string_from_system(),
		"updated_at": Time.get_datetime_string_from_system()
	}
	
	current_profile_name = profile_name
	return save_profile()

func load_profile(profile_name: String) -> bool:
	var profile_path = PROFILES_DIR + profile_name + ".json"
	
	if not FileAccess.file_exists(profile_path):
		print("❌ Perfil no encontrado: ", profile_name)
		return false
	
	var file = FileAccess.open(profile_path, FileAccess.READ)
	if file == null:
		print("❌ Error loading profile: ", FileAccess.get_open_error())
		return false
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	
	if json.parse(json_string) != OK:
		print("❌ Error parsing profile JSON")
		return false
	
	current_profile = json.data
	current_profile_name = profile_name
	save_last_profile()  # Guardar como último perfil usado
	print("✓ Perfil cargado: ", profile_name)
	return true

func save_profile() -> bool:
	if current_profile_name.is_empty():
		print("❌ No hay perfil seleccionado para guardar")
		return false
	
	current_profile["updated_at"] = Time.get_datetime_string_from_system()
	
	var profile_path = PROFILES_DIR + current_profile_name + ".json"
	var json = JSON.stringify(current_profile)
	
	var file = FileAccess.open(profile_path, FileAccess.WRITE)
	if file == null:
		print("❌ Error saving profile: ", FileAccess.get_open_error())
		return false
	
	file.store_string(json)
	print("✓ Perfil guardado: ", current_profile_name)
	return true

func update_stats(won: bool, character_used: int) -> void:
	if current_profile_name.is_empty():
		print("ℹ No hay perfil activo para actualizar")
		return
	
	# Actualizar estadísticas
	if won:
		current_profile["wins"] += 1
	else:
		current_profile["losses"] += 1
	
	# Registrar personaje más usado
	current_profile["main_character"] = character_used
	
	save_profile()

func delete_profile(profile_name: String) -> bool:
	var profile_path = PROFILES_DIR + profile_name + ".json"
	
	if not FileAccess.file_exists(profile_path):
		print("❌ Perfil no encontrado")
		return false
	
	if DirAccess.remove_absolute(profile_path) != OK:
		print("❌ Error al eliminar perfil")
		return false
	
	if current_profile_name == profile_name:
		current_profile_name = ""
		current_profile = {
			"name": "",
			"main_character": 0,
			"wins": 0,
			"losses": 0,
			"created_at": "",
			"updated_at": ""
		}
	
	print("✓ Perfil eliminado: ", profile_name)
	return true

func get_profile_name() -> String:
	return current_profile.get("name", "")

func get_win_rate() -> float:
	var total = current_profile["wins"] + current_profile["losses"]
	if total == 0:
		return 0.0
	return float(current_profile["wins"]) / float(total) * 100.0

func get_total_games() -> int:
	return current_profile["wins"] + current_profile["losses"]

func export_to_json() -> String:
	return JSON.stringify(current_profile)

func get_profiles_directory() -> String:
	return PROFILES_DIR

func save_last_profile() -> void:
	"""Guarda el nombre del perfil actualmente cargado para cargar la próxima vez"""
	if current_profile_name.is_empty():
		return
	
	var file = FileAccess.open(LAST_PROFILE_FILE, FileAccess.WRITE)
	if file == null:
		print("❌ Error saving last profile: ", FileAccess.get_open_error())
		return
	
	file.store_string(current_profile_name)
	print("✓ Último perfil guardado: ", current_profile_name)

func load_last_profile() -> void:
	"""Carga automáticamente el último perfil usado"""
	if not FileAccess.file_exists(LAST_PROFILE_FILE):
		print("ℹ No hay perfil guardado previamente")
		return
	
	var file = FileAccess.open(LAST_PROFILE_FILE, FileAccess.READ)
	if file == null:
		print("❌ Error loading last profile: ", FileAccess.get_open_error())
		return
	
	var profile_name = file.get_as_text().strip_edges()
	
	if not profile_name.is_empty() and profile_exists(profile_name):
		load_profile(profile_name)
		print("✓ Último perfil cargado automáticamente: ", profile_name)
	else:
		print("ℹ El perfil guardado no existe")
