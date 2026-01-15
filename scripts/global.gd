extends Node

# Configuración del juego
const MAX_HP = 100
const MAX_LIVES = 3
const PLAYER_SPEED = 600
const SPRINT_SPEED = 1000
const JUMP_VELOCITY = -1200
const WALL_JUMP_VELOCITY = Vector2(800, -1100)
const GRAVITY = 3000
const DOUBLE_TAP_TIME = 0.3
const INITIAL_BALL_SPEED = 1600
const BALL_SPEED_INCREMENT = 300
const MAX_BALL_SPEED = 4000
const BASE_DAMAGE = 25
const KNOCKBACK_FORCE = 800
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

# Ganador
var winner: int = 0

# Control de inicio de juego
var game_should_start: bool = true

# Reiniciar el juego
func reset_game() -> void:
	player1_lives = MAX_LIVES
	player2_lives = MAX_LIVES
	winner = 0
	player1_character = 0
	player2_character = 0
	selected_map = 0
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
