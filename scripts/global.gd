extends Node

const CONFIG_FILE = "user://settings.cfg"

# Configuración del juego
const MAX_HP = 100
const MAX_LIVES = 3
const PLAYER_SPEED = 570
const SPRINT_SPEED = 950
const JUMP_VELOCITY = -1140
const WALL_JUMP_VELOCITY = Vector2(760, -1045)
const GRAVITY = 2850
const DOUBLE_TAP_TIME = 0.3
const INITIAL_BALL_SPEED = 1600
const BALL_SPEED_INCREMENT = 300
const MAX_BALL_SPEED = 4000
const BASE_DAMAGE = 25
const KNOCKBACK_FORCE = 760
const INVULNERABILITY_TIME = 0.5

# Umbrales de velocidad para sonidos de golpe
const WEAK_THRESHOLD = 2000
const MEDIUM_THRESHOLD = 3000

# Selección de personajes y mapa
var player1_character: int = 0
var player2_character: int = 0
var selected_map: int = 0

# Sistema de vidas
var player1_lives: int = MAX_LIVES
var player2_lives: int = MAX_LIVES

# Debug
var god_mode: bool = false

# Opciones
var skip_intro: bool = false

# Ganador
var winner: int = 0

# Control de inicio de juego
var game_should_start: bool = true

# DEBUG: One-hit kill mode
var debug_one_hit_kill: bool = false

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE)
	
	if err == OK:
		skip_intro = config.get_value("gameplay", "skip_intro", false)
		
		# Aplicar volumen guardado
		var volume = config.get_value("audio", "volume", 100.0)
		apply_volume(volume)

func apply_volume(volume: float) -> void:
	var db = linear_to_db(volume / 100.0)
	if volume <= 0:
		db = -80
	# Bus 0 es Master
	AudioServer.set_bus_volume_db(0, db)

# Reiniciar el juego
func reset_game() -> void:
	player1_lives = MAX_LIVES
	player2_lives = MAX_LIVES
	winner = 0
	player1_character = 0
	player2_character = 0
	selected_map = 0
	game_should_start = true

# Reiniciar solo el match (mantiene personajes seleccionados)
func reset_match() -> void:
	player1_lives = MAX_LIVES
	player2_lives = MAX_LIVES
	winner = 0
	game_should_start = true

# Restar una vida a un jugador
func player_lost_life(player_id: int) -> void:
	if player_id == 1:
		player1_lives -= 1
	elif player_id == 2:
		player2_lives -= 1
	
	check_game_over()

# Verificar si hay ganador
func check_game_over() -> bool:
	if player1_lives <= 0:
		winner = 2
		return true
	elif player2_lives <= 0:
		winner = 1
		return true
	return false
