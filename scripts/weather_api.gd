extends Node

# Configuración de la API
const API_KEY = "3ee1b5e0ae06fb81149e6f6332a594dc"  # Obtén una gratis en https://openweathermap.org/api
const CITY = "Barcelona"  # Cambia a tu ciudad
const API_URL = "https://api.openweathermap.org/data/2.5/weather?q=%s&appid=%s"

# MODO PRUEBA: Cambiar a true para forzar clima sin usar la API
const FORCE_TEST_WEATHER = false  # true = modo prueba, false = API real
const TEST_WEATHER_TYPE = "Lloviendo"  # Opciones: "Claro", "Nublado", "Llovizna", "Lloviendo", "Tormenta", "Nevando"

signal weather_data_received(weather_type: String, weather_description: String)
signal api_validation_result(is_valid: bool, message: String)

var http_request: HTTPRequest
var current_weather_type: String = "Desconocido"  # Claro, Nublado, Lloviendo, Nevando, etc.

func _ready() -> void:
	# Crear HTTPRequest para peticiones
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func fetch_weather() -> void:
	# MODO PRUEBA: Forzar clima para testing
	if FORCE_TEST_WEATHER:
		print("MODO PRUEBA: Forzando clima - ", TEST_WEATHER_TYPE)
		current_weather_type = TEST_WEATHER_TYPE
		api_validation_result.emit(true, "✅ API del tiempo: MODO PRUEBA - " + TEST_WEATHER_TYPE)
		weather_data_received.emit(current_weather_type, "Clima de prueba")
		return
	
	# API Real
	var url = API_URL % [CITY, API_KEY]
	print("Consultando clima de ", CITY, "...")
	
	var error = http_request.request(url)
	if error != OK:
		push_error("Error al hacer petición HTTP: ", error)
		api_validation_result.emit(false, "❌ API del tiempo: Error de conexión")
		# Emitir clima desconocido por defecto si falla
		weather_data_received.emit("Desconocido", "Error de conexión")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		var error_msg = ""
		if response_code == 401:
			error_msg = "❌ API del tiempo: API Key inválida o no configurada"
		elif response_code == 404:
			error_msg = "❌ API del tiempo: Ciudad no encontrada"
		else:
			error_msg = "❌ API del tiempo: Error HTTP " + str(response_code)
		
		push_error(error_msg)
		api_validation_result.emit(false, error_msg)
		weather_data_received.emit("Desconocido", "Error HTTP " + str(response_code))
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	
	if error != OK:
		push_error("Error parseando JSON: ", json.get_error_message())
		weather_data_received.emit(false, "Error parseando datos")
		return
	
	var data = json.data
	
	# Verificar si hay lluvia
	var is_raining = false
	var weather_description = ""
	
	if data.has("weather") and data.weather.size() > 0:
		var weather = data.weather[0]
		weather_description = weather.description if weather.has("description") else "Desconocido"
		
		# Categorizar el clima según el ID de OpenWeatherMap
		if weather.has("id"):
			var weather_id = weather.id
			is_raining = (weather_id >= 200 and weather_id < 600)
			
			# Categorías principales
			if weather_id >= 200 and weather_id < 300:
				current_weather_type = "Tormenta"
			elif weather_id >= 300 and weather_id < 400:
				current_weather_type = "Llovizna"
			elif weather_id >= 500 and weather_id < 600:
				current_weather_type = "Lloviendo"
			elif weather_id >= 600 and weather_id < 700:
				current_weather_type = "Nevando"
			elif weather_id >= 700 and weather_id < 800:
				current_weather_type = "Nublado"
			elif weather_id == 800:
				current_weather_type = "Claro"
			elif weather_id > 800:
				current_weather_type = "Nublado"
			else:
				current_weather_type = "Desconocido"
	
	print("Clima actual: ", weather_description, " | ", current_weather_type)
	api_validation_result.emit(true, "✅ API del tiempo: Conectada correctamente (" + CITY + ")")
	weather_data_received.emit(current_weather_type, weather_description)
