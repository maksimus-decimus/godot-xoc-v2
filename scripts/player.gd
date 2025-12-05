extends CharacterBody2D

@export var player_id: int = 1
@onready var visual_container = $VisualContainer
@onready var sprite_node = $VisualContainer/Sprite2D
@onready var color_rect = $VisualContainer/ColorRect
@onready var hit_area = $HitArea
@onready var hit_indicator = $HitArea/HitIndicator
@onready var collision_shape = $CollisionShape2D
@onready var audio_player = $AudioStreamPlayer

var hp: float = Global.MAX_HP
var max_hp: float = Global.MAX_HP
var is_hitting: bool = false
var invulnerable: bool = false
var last_direction: Vector2 = Vector2.RIGHT

# Sistema de movimiento avanzado
var is_sprinting: bool = false
var jumps_remaining: int = 2
var can_wall_jump: bool = false

# Doble tap para sprint
var last_tap_time_right: float = 0.0
var last_tap_time_left: float = 0.0
var tap_direction: float = 0.0

# Sonidos de daño
var hit_sounds: Array[AudioStream] = []

# Sprites del personaje
var sprites = {
	"idle": null,
	"move": null,
	"jump": null,
	"hit1": null,
	"hit1_2": null,
	"hit1_3": null,
	"block": null,
	"dmg": null
}
var current_sprite_state: String = "idle"
var has_sprites: bool = false

signal player_damaged(player_id: int, damage: float)
signal player_defeated(player_id: int)

func _ready() -> void:
	load_hit_sounds()
	load_character_sprites()
	setup_character()

func load_hit_sounds() -> void:
	# Cargar todos los sonidos get_hit de la carpeta sound/sfx/
	hit_sounds.clear()
	hit_sounds.append(load("res://sound/sfx/get_hit1.wav"))
	hit_sounds.append(load("res://sound/sfx/get_hit2.wav"))
	hit_sounds.append(load("res://sound/sfx/get_hit3.wav"))
	hit_sounds.append(load("res://sound/sfx/get_hit4.wav"))

func load_character_sprites() -> void:
	# Determinar personaje seleccionado
	var character = Global.player1_character if player_id == 1 else Global.player2_character
	
	# Cargar sprites solo si es Don Quixote (character 0)
	if character == 0:
		var base_path = "res://assets/players/don_quixote/sprites/"
		if ResourceLoader.exists(base_path + "idle.png"):
			sprites["idle"] = load(base_path + "idle.png")
			sprites["move"] = load(base_path + "move.png")
			sprites["jump"] = load(base_path + "jump.png")
			sprites["hit1"] = load(base_path + "hit1.png")
			sprites["hit1_2"] = load(base_path + "hit1_2.png")
			sprites["hit1_3"] = load(base_path + "hit1_3.png")
			sprites["block"] = load(base_path + "block.png")
			sprites["dmg"] = load(base_path + "dmg.png")
			has_sprites = true
			color_rect.visible = false  # Ocultar placeholder
			sprite_node.visible = true
		else:
			has_sprites = false
			color_rect.visible = true
			sprite_node.visible = false
	else:
		# Ishmael u otros personajes usan placeholder
		has_sprites = false
		color_rect.visible = true
		sprite_node.visible = false

func update_sprite_state(state: String) -> void:
	if not has_sprites or current_sprite_state == state:
		return
	
	if sprites.has(state) and sprites[state] != null:
		sprite_node.texture = sprites[state]
		current_sprite_state = state

func play_random_hit_sound() -> void:
	if hit_sounds.size() > 0:
		var random_sound = hit_sounds[randi() % hit_sounds.size()]
		audio_player.stream = random_sound
		audio_player.play()

func setup_character() -> void:
	# Configurar apariencia según personaje seleccionado
	var character = Global.player1_character if player_id == 1 else Global.player2_character
	
	if not has_sprites:
		# Usar placeholder de colores
		if character == 0:  # Cuadrado rojo
			color_rect.color = Color.RED if player_id == 1 else Color.DARK_RED
		else:  # Círculo azul
			color_rect.color = Color.BLUE if player_id == 1 else Color.CYAN
	else:
		# Usar sprite inicial
		update_sprite_state("idle")
	
	hp = max_hp

func _physics_process(delta: float) -> void:
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += Global.GRAVITY * delta
	else:
		velocity.y = 0
		jumps_remaining = 2  # Resetear doble salto al tocar suelo
	
	# Detectar si está tocando pared
	can_wall_jump = is_on_wall() and not is_on_floor()
	
	# Input según el jugador
	var direction_x = 0.0
	var jump_pressed = false
	var hit_pressed = false
	var up_pressed = false
	
	if player_id == 1:
		direction_x = Input.get_axis("p1_left", "p1_right")
		jump_pressed = Input.is_action_just_pressed("p1_up")
		hit_pressed = Input.is_action_just_pressed("p1_hit")
		up_pressed = Input.is_action_pressed("p1_up")
		
		# Detectar doble tap para sprint
		if Input.is_action_just_pressed("p1_right"):
			if Time.get_ticks_msec() / 1000.0 - last_tap_time_right < Global.DOUBLE_TAP_TIME:
				is_sprinting = true
				tap_direction = 1.0
			last_tap_time_right = Time.get_ticks_msec() / 1000.0
		
		if Input.is_action_just_pressed("p1_left"):
			if Time.get_ticks_msec() / 1000.0 - last_tap_time_left < Global.DOUBLE_TAP_TIME:
				is_sprinting = true
				tap_direction = -1.0
			last_tap_time_left = Time.get_ticks_msec() / 1000.0
	else:
		direction_x = Input.get_axis("p2_left", "p2_right")
		jump_pressed = Input.is_action_just_pressed("p2_up")
		hit_pressed = Input.is_action_just_pressed("p2_hit")
		up_pressed = Input.is_action_pressed("p2_up")
		
		# Detectar doble tap para sprint
		if Input.is_action_just_pressed("p2_right"):
			if Time.get_ticks_msec() / 1000.0 - last_tap_time_right < Global.DOUBLE_TAP_TIME:
				is_sprinting = true
				tap_direction = 1.0
			last_tap_time_right = Time.get_ticks_msec() / 1000.0
		
		if Input.is_action_just_pressed("p2_left"):
			if Time.get_ticks_msec() / 1000.0 - last_tap_time_left < Global.DOUBLE_TAP_TIME:
				is_sprinting = true
				tap_direction = -1.0
			last_tap_time_left = Time.get_ticks_msec() / 1000.0
	
	# Desactivar sprint si cambia de dirección o se detiene
	if direction_x == 0 or (is_sprinting and sign(direction_x) != sign(tap_direction)):
		is_sprinting = false
	
	# Sistema de salto (normal, doble, wall jump)
	if jump_pressed:
		if is_on_floor():
			# Salto normal desde el suelo
			velocity.y = Global.JUMP_VELOCITY
			jumps_remaining = 1  # Queda 1 salto (el doble salto)
		elif can_wall_jump:
			# Wall jump
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * Global.WALL_JUMP_VELOCITY.x
			velocity.y = Global.WALL_JUMP_VELOCITY.y
			jumps_remaining = 1  # Resetear para permitir doble salto después
		elif jumps_remaining > 0:
			# Doble salto en el aire
			velocity.y = Global.JUMP_VELOCITY * 0.9  # Un poco menos potente
			jumps_remaining -= 1
	
	# Movimiento horizontal
	var current_speed = Global.SPRINT_SPEED if is_sprinting else Global.PLAYER_SPEED
	
	if direction_x != 0:
		velocity.x = direction_x * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 10)
	
	# Actualizar dirección del golpe basado en input direccional
	var hit_direction = Vector2.ZERO
	
	# Determinar dirección vertical del golpe
	if player_id == 1:
		if Input.is_action_pressed("p1_up"):
			hit_direction.y = -1  # Arriba
		elif Input.is_action_pressed("p1_down"):
			hit_direction.y = 1   # Abajo
	else:
		if Input.is_action_pressed("p2_up"):
			hit_direction.y = -1  # Arriba
		elif Input.is_action_pressed("p2_down"):
			hit_direction.y = 1   # Abajo
	
	# Determinar dirección horizontal del golpe
	if direction_x != 0:
		hit_direction.x = direction_x
	
	# Si hay alguna dirección presionada, actualizar last_direction
	if hit_direction.length() > 0:
		last_direction = hit_direction.normalized()
	elif direction_x != 0:
		# Si solo hay movimiento horizontal sin input vertical
		last_direction = Vector2(direction_x, 0).normalized()
	
	# Ejecutar golpe
	if hit_pressed and not is_hitting:
		hit()
	
	move_and_slide()
	
	# Actualizar posición del área de golpe según la dirección
	if not is_hitting:
		update_hit_area_position()
	
	# Actualizar sprite según estado
	update_sprite_animation(direction_x)

func update_hit_area_position() -> void:
	# Posicionar el área de golpe delante del jugador según su última dirección
	var offset_distance = 50.0
	hit_area.position = last_direction * offset_distance

func update_sprite_animation(direction_x: float) -> void:
	if not has_sprites:
		return
	
	# Voltear sprite según dirección
	if direction_x < 0:
		sprite_node.flip_h = true
	elif direction_x > 0:
		sprite_node.flip_h = false
	
	# Cambiar sprite según estado
	if is_hitting:
		# Mantener sprite de hit (se maneja en hit())
		return
	elif not is_on_floor():
		update_sprite_state("jump")
	elif abs(velocity.x) > 10:
		update_sprite_state("move")
	else:
		update_sprite_state("idle")

func hit() -> void:
	is_hitting = true
	hit_area.monitoring = true
	hit_indicator.visible = true
	
	# Posicionar el área de golpe en la dirección actual
	update_hit_area_position()
	
	# Cambiar a sprite de golpe
	if has_sprites:
		update_sprite_state("hit1")
		# Animación de secuencia de golpe
		await get_tree().create_timer(0.05).timeout
		update_sprite_state("hit1_2")
		await get_tree().create_timer(0.05).timeout
		update_sprite_state("hit1_3")
	
	# Animación visual de golpe del jugador (escala del contenedor)
	var tween = create_tween()
	tween.tween_property(visual_container, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(visual_container, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Animación del indicador de golpe
	var indicator_tween = create_tween()
	indicator_tween.tween_property(hit_indicator, "modulate:a", 1.0, 0.05)
	indicator_tween.tween_property(hit_indicator, "modulate:a", 0.0, 0.15)
	
	await get_tree().create_timer(0.1).timeout
	hit_area.monitoring = false
	hit_indicator.visible = false
	is_hitting = false

func take_damage(damage: float, knockback_direction: Vector2) -> void:
	if invulnerable:
		return
	
	hp -= damage
	player_damaged.emit(player_id, damage)
	
	# Mostrar sprite de daño
	if has_sprites:
		update_sprite_state("dmg")
	
	# Reproducir sonido aleatorio de daño
	play_random_hit_sound()
	
	# Knockback
	velocity = knockback_direction * Global.KNOCKBACK_FORCE
	
	# Invulnerabilidad temporal
	invulnerable = true
	blink_effect()
	
	await get_tree().create_timer(Global.INVULNERABILITY_TIME).timeout
	invulnerable = false
	
	# Verificar si murió
	if hp <= 0:
		hp = 0
		player_defeated.emit(player_id)

func blink_effect() -> void:
	for i in range(5):
		visual_container.modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		visual_container.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func respawn(spawn_position: Vector2) -> void:
	position = spawn_position
	hp = max_hp
	velocity = Vector2.ZERO
	invulnerable = true
	
	await get_tree().create_timer(1.0).timeout
	invulnerable = false
