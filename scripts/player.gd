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
var is_dead: bool = false
var can_move: bool = true
var last_direction: Vector2 = Vector2.RIGHT
var hit_connected: bool = false  # Track if hit connected with ball

# Sistema de ultimate
var combo_count: int = 0
var ultimate_ready: bool = false
var is_ulting: bool = false
var is_parrying: bool = false
var parry_hit_received: bool = false
const COMBO_MAX: int = 4

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

# Sonidos de ataque por personaje
var attack_sounds: Array[String] = []

# Sonidos de swing (golpe al aire)
var swing_sounds: Array[AudioStream] = []

# Offsets ajustables desde el Inspector (Y negativo = arriba, positivo = abajo)
@export_group("Sprite Offsets")
@export var idle_offset: Vector2 = Vector2(0, 0)
@export var move_offset: Vector2 = Vector2(0, 0)
@export var jump_offset: Vector2 = Vector2(0, 0)
@export var hit1_offset: Vector2 = Vector2(0, 0)
@export var hit1_2_offset: Vector2 = Vector2(0, 0)
@export var hit1_3_offset: Vector2 = Vector2(0, 0)
@export var block_offset: Vector2 = Vector2(0, 0)
@export var dmg_offset: Vector2 = Vector2(0, 0)
@export var ultimate_offset: Vector2 = Vector2(0, 0)
@export var victory_offset: Vector2 = Vector2(0, 0)

# Configuración de hitbox
@export_group("Hitbox")
@export var hit_distance: float = 50.0
@export var hit_offset: Vector2 = Vector2(0, 0)

# Sprites del personaje
var sprites = {
	"idle": null,
	"move": null,
	"jump": null,
	"hit1": null,
	"hit1_2": null,
	"hit1_3": null,
	"block": null,
	"dmg": null,
	"ultimate": null
}

# Sprites de animación de ultimate (array de frames)
var ultimate_frames: Array[Texture2D] = []

var current_sprite_state: String = "idle"
var has_sprites: bool = false

signal player_damaged(player_id: int, damage: float)
signal player_defeated(player_id: int)
signal combo_changed(player_id: int, combo: int)
signal ultimate_activated(player_id: int)
signal don_ultimate_attack()
signal ishmael_parry_hit()
signal ishmael_parry_success()

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
	
	# Cargar sonido de swing
	swing_sounds.clear()
	swing_sounds.append(load("res://sound/sfx/golpe/swing.wav"))
	hit_sounds.append(load("res://sound/sfx/get_hit4.wav"))

func load_character_sprites() -> void:
	# Determinar personaje seleccionado
	var character = Global.player1_character if player_id == 1 else Global.player2_character
	
	print("Player ", player_id, " cargando character: ", character)
	
	var base_path = ""
	
	# Determinar ruta según personaje (¡RESPETAR MAYÚSCULAS!)
	if character == 0:
		base_path = "res://assets/players/don_quixote/Sprites/"
	elif character == 1:
		base_path = "res://assets/players/ishmael/Sprites/"
	
	print("Ruta sprites: ", base_path)
	
	# Intentar cargar sprites si hay una ruta válida
	if base_path != "" and ResourceLoader.exists(base_path + "idle.png"):
		sprites["idle"] = load(base_path + "idle.png")
		sprites["move"] = load(base_path + "move.png")
		sprites["jump"] = load(base_path + "jump.png")
		sprites["hit1"] = load(base_path + "hit1.png")
		sprites["hit1_2"] = load(base_path + "hit1_2.png")
		sprites["hit1_3"] = load(base_path + "hit1_3.png")
		sprites["block"] = load(base_path + "block.png")
		sprites["dmg"] = load(base_path + "dmg.png")
		
		# Cargar sprites de ultimate según personaje
		ultimate_frames.clear()
		if character == 0:  # Don Quixote - skill3
			sprites["ultimate"] = load(base_path + "skill3_1.png")
			ultimate_frames.append(load(base_path + "skill3_1.png"))
			ultimate_frames.append(load(base_path + "skill3_2.png"))
			ultimate_frames.append(load(base_path + "skill3_3.png"))
			ultimate_frames.append(load(base_path + "skill3_4.png"))
			if ResourceLoader.exists(base_path + "skill3_5.png"):
				ultimate_frames.append(load(base_path + "skill3_5.png"))
		elif character == 1:  # Ishmael - ultra
			sprites["ultimate"] = load(base_path + "ultra_1.png")
			ultimate_frames.append(load(base_path + "ultra_1.png"))
			ultimate_frames.append(load(base_path + "ultra_2.png"))
			ultimate_frames.append(load(base_path + "ultra_3.png"))
			ultimate_frames.append(load(base_path + "ultra_4.png"))
		
		has_sprites = true
		color_rect.visible = false  # Ocultar placeholder
		sprite_node.visible = true
		
		# Configurar centrado del sprite
		sprite_node.centered = true
		sprite_node.offset = Vector2.ZERO
		print("Sprites cargados correctamente!")
	else:
		# Usar placeholder si no hay sprites
		has_sprites = false
		color_rect.visible = true
		sprite_node.visible = false
		print("No se encontraron sprites, usando placeholder")

func update_sprite_state(state: String) -> void:
	if not has_sprites or current_sprite_state == state:
		return
	
	if sprites.has(state) and sprites[state] != null:
		sprite_node.texture = sprites[state]
		current_sprite_state = state
		
		# Aplicar offset específico para cada sprite
		sprite_node.centered = true
		var offset = Vector2.ZERO
		match state:
			"idle": offset = idle_offset
			"move": offset = move_offset
			"jump": offset = jump_offset
			"hit1": offset = hit1_offset
			"hit1_2": offset = hit1_2_offset
			"hit1_3": offset = hit1_3_offset
			"block": offset = block_offset
			"dmg": offset = dmg_offset
			"ultimate": offset = ultimate_offset
		sprite_node.offset = offset

func play_random_hit_sound() -> void:
	if hit_sounds.size() > 0:
		var random_sound = hit_sounds[randi() % hit_sounds.size()]
		audio_player.stream = random_sound
		audio_player.play()

func setup_character() -> void:
	# Configurar apariencia según personaje seleccionado
	var character = Global.player1_character if player_id == 1 else Global.player2_character
	
	# Ajustar hitbox según personaje
	if character == 0:  # Don Quixote
		hit_distance = 50.0
		hit_offset = Vector2(0, 0)
	elif character == 1:  # Ishmael
		hit_distance = 70.0  # Más alcance hacia adelante
		hit_offset = Vector2(10, 0)  # Desplazar un poco más hacia adelante
	
	# Cargar sonidos de ataque según personaje
	attack_sounds.clear()
	if character == 0:  # Don Quixote
		attack_sounds.append("res://sound/sfx/players/don_quixote/attack/battle_s2_10301_1.wav")
		attack_sounds.append("res://sound/sfx/players/don_quixote/attack/battle_s3_10301_1_1.wav")
		attack_sounds.append("res://sound/sfx/players/don_quixote/attack/battle_s3_10301_1_2.wav")
		attack_sounds.append("res://sound/sfx/players/don_quixote/attack/battle_s3_10301_1_3.wav")
	elif character == 1:  # Ishmael
		attack_sounds.append("res://sound/sfx/players/ishmael/attack/battle_s2_10811_1_1.wav")
		attack_sounds.append("res://sound/sfx/players/ishmael/attack/battle_s2_10811_1_1-01.wav")
		attack_sounds.append("res://sound/sfx/players/ishmael/attack/battle_s2_10811_1_1-02.wav")
		attack_sounds.append("res://sound/sfx/players/ishmael/attack/battle_s2_10811_1_2-02.wav")
	
	print("Player ", player_id, " tiene ", attack_sounds.size(), " sonidos de ataque")
	
	if not has_sprites:
		# Usar placeholder de colores
		if character == 0:  # Cuadrado rojo
			color_rect.color = Color.RED if player_id == 1 else Color.DARK_RED
		else:  # Círculo azul
			color_rect.color = Color.BLUE if player_id == 1 else Color.CYAN
	else:
		# Configurar sprite inicial con centrado y dirección
		sprite_node.centered = true
		sprite_node.offset = Vector2.ZERO
		# P1 mira a la derecha, P2 mira a la izquierda
		sprite_node.flip_h = (player_id == 2)
		
		# Configurar offsets según el personaje (no por player_id)
		# Así ambos jugadores con el mismo personaje tienen la misma altura
		if character == 0:  # Don Quixote
			# Aquí van los offsets de Don Quixote
			idle_offset = Vector2(0, -120)
			move_offset = Vector2(0, 0)
			jump_offset = Vector2(0, 0)
			hit1_offset = Vector2(0, 0)
			hit1_2_offset = Vector2(0, 0)
			hit1_3_offset = Vector2(0, 0)
			block_offset = Vector2(0, 0)
			dmg_offset = Vector2(0, 0)
			victory_offset = Vector2(0, 25)
			# Configurar hitbox de Don Quixote
			hit_distance = 50.0
			hit_offset = Vector2(0, 0)
		elif character == 1:  # Ishmael
			# Copiar los mismos offsets que Don Quixote para mantener altura
			idle_offset = Vector2(0, 0)
			move_offset = Vector2(0, 0)
			jump_offset = Vector2(0, 0)
			hit1_offset = Vector2(0, 0)
			hit1_2_offset = Vector2(0, 0)
			hit1_3_offset = Vector2(0, 0)
			block_offset = Vector2(0, 0)
			dmg_offset = Vector2(0, 0)
			victory_offset = Vector2(0, 0)
			# Configurar hitbox dwde Ishmael
			hit_distance = 100.0
			hit_offset = Vector2(0, 0)
		
		# Forzar carga del sprite inicial
		current_sprite_state = ""
		update_sprite_state("idle")
	
	hp = max_hp

func _physics_process(delta: float) -> void:
	# Input según el jugador (leer inputs siempre)
	var direction_x = 0.0
	var jump_pressed = false
	var hit_pressed = false
	var up_pressed = false
	var ultimate_pressed = false
	
	if player_id == 1:
		direction_x = Input.get_axis("p1_left", "p1_right")
		jump_pressed = Input.is_action_just_pressed("p1_up")
		hit_pressed = Input.is_action_just_pressed("p1_hit")
		up_pressed = Input.is_action_pressed("p1_up")
		ultimate_pressed = Input.is_action_just_pressed("p1_ultimate")
	else:
		direction_x = Input.get_axis("p2_left", "p2_right")
		jump_pressed = Input.is_action_just_pressed("p2_up")
		hit_pressed = Input.is_action_just_pressed("p2_hit")
		up_pressed = Input.is_action_pressed("p2_up")
		ultimate_pressed = Input.is_action_just_pressed("p2_ultimate")
	
	# Activar ultimate (funciona incluso si can_move es false)
	if ultimate_pressed:
		print("Player ", player_id, " presionó ultimate - ready: ", ultimate_ready, " ulting: ", is_ulting)
		activate_ultimate()
	
	# Si el jugador no puede moverse, no procesar el resto de inputs
	if not can_move:
		return
	
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += Global.GRAVITY * delta
	else:
		velocity.y = 0
		jumps_remaining = 2  # Resetear doble salto al tocar suelo
	
	# Detectar si está tocando pared
	can_wall_jump = is_on_wall() and not is_on_floor()
	
	# Detectar doble tap para sprint
	if player_id == 1:
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
	hit_area.position = last_direction * hit_distance + hit_offset

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
	hit_connected = false  # Reset hit detection
	hit_area.monitoring = true
	hit_indicator.visible = true
	
	# Reproducir sonido de ataque aleatorio si hay sonidos disponibles
	if attack_sounds.size() > 0:
		var random_attack = attack_sounds[randi() % attack_sounds.size()]
		audio_player.stream = load(random_attack)
		audio_player.play()
	
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
	
	# Si no conectó con la pelota, reproducir sonido de swing
	if not hit_connected and swing_sounds.size() > 0:
		var random_swing = swing_sounds[randi() % swing_sounds.size()]
		audio_player.stream = random_swing
		audio_player.play()
	
	is_hitting = false

func take_damage(damage: float, knockback_direction: Vector2) -> void:
	if invulnerable or is_dead:
		return
	
	# God mode: no recibir daño
	if Global.god_mode:
		return
	
	# Si está en modo parry (Ishmael), activar el counter
	if is_parrying:
		parry_hit_received = true
		ishmael_parry_hit.emit()
		return
	
	hp -= damage
	player_damaged.emit(player_id, damage)
	
	# Verificar si murió
	if hp <= 0:
		hp = 0
		is_dead = true
		player_defeated.emit(player_id)
		# Ejecutar animación de muerte (await para que termine antes de continuar)
		await death_animation(knockback_direction)
		return
	
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

func death_animation(knockback_direction: Vector2) -> void:
	# Mostrar sprite de daño
	if has_sprites:
		update_sprite_state("dmg")
	
	# Reproducir sonido de daño
	play_random_hit_sound()
	
	# Desactivar colisión para que no interfiera
	collision_shape.set_deferred("disabled", true)
	hit_area.monitoring = false
	
	print("Iniciando animación de muerte para jugador ", player_id)
	
	# Impulso inicial: salta hacia arriba y cae fuera de la escena
	velocity.x = knockback_direction.x * 150  # Un poco de movimiento horizontal
	velocity.y = -400  # Impulso hacia arriba
	
	# Animación de salto y caída (sin rotación ni fade)
	var flight_time = 2.5  # Duración de la animación
	var elapsed = 0.0
	
	while elapsed < flight_time and is_inside_tree():
		var delta = get_physics_process_delta_time()
		elapsed += delta
		
		# Aplicar gravedad normal para caída natural
		velocity.y += Global.GRAVITY * delta
		
		# Mover
		position += velocity * delta
		
		if is_inside_tree():
			await get_tree().process_frame
		else:
			break
	
	print("Animación de muerte completada para jugador ", player_id)
	
	# Resetear is_dead al final de la animación
	is_dead = false

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
	is_dead = false
	
	# Restaurar visuales
	visual_container.visible = true
	visual_container.modulate.a = 1.0
	visual_container.rotation = 0.0
	collision_shape.set_deferred("disabled", false)
	
	# Volver a idle
	if has_sprites:
		current_sprite_state = ""
		update_sprite_state("idle")
	
	await get_tree().create_timer(1.0).timeout
	invulnerable = false

func increment_combo() -> void:
	combo_count += 1
	if combo_count >= COMBO_MAX:
		combo_count = COMBO_MAX
		ultimate_ready = true
	combo_changed.emit(player_id, combo_count)

func reset_combo() -> void:
	combo_count = 0
	ultimate_ready = false
	combo_changed.emit(player_id, combo_count)

func activate_ultimate() -> void:
	print("activate_ultimate llamado - Player: ", player_id, " ready: ", ultimate_ready, " ulting: ", is_ulting)
	if not ultimate_ready or is_ulting:
		print("Ultimate bloqueado - ready: ", ultimate_ready, " ulting: ", is_ulting)
		return
	
	print("¡ACTIVANDO ULTIMATE Player ", player_id, "!")
	is_ulting = true
	ultimate_ready = false
	combo_count = 0
	combo_changed.emit(player_id, combo_count)
	
	# Emitir señal para que game_manager maneje los efectos visuales (zoom, etc.)
	ultimate_activated.emit(player_id)
	
	# Ejecutar lógica específica según personaje
	var character = Global.player1_character if player_id == 1 else Global.player2_character
	
	if character == 0:  # Don Quixote
		await execute_don_ultimate()
	elif character == 1:  # Ishmael
		await execute_ishmael_ultimate()
	
	is_ulting = false
	
	# Volver a idle
	if has_sprites:
		current_sprite_state = ""
		update_sprite_state("idle")

func execute_don_ultimate() -> void:
	# Reproducir voz de ulti de Don Quixote
	var ulti_voice = AudioStreamPlayer.new()
	ulti_voice.stream = load("res://sound/sfx/players/don_quixote/ulti_don.wav")
	ulti_voice.bus = "SFX"
	add_child(ulti_voice)
	ulti_voice.play()
	ulti_voice.finished.connect(func(): ulti_voice.queue_free())
	
	# Animar sprites de skill3_1 a skill3_4/5
	if ultimate_frames.size() > 0:
		for i in range(ultimate_frames.size()):
			sprite_node.texture = ultimate_frames[i]
			sprite_node.offset = ultimate_offset  # Aplicar offset de ultimate
			await get_tree().create_timer(0.15).timeout
	
	# Señal para que game_manager lance la pelota con 999 de daño
	don_ultimate_attack.emit()

func execute_ishmael_ultimate() -> void:
	# Reproducir voz de ulti de Ishmael
	var ulti_voice = AudioStreamPlayer.new()
	ulti_voice.stream = load("res://sound/sfx/players/ishmael/ultra/ulti_ishm.wav")
	ulti_voice.bus = "SFX"
	add_child(ulti_voice)
	ulti_voice.play()
	ulti_voice.finished.connect(func(): ulti_voice.queue_free())
	
	# Mostrar primer frame de ultra
	if ultimate_frames.size() > 0:
		sprite_node.texture = ultimate_frames[0]
		sprite_node.offset = ultimate_offset  # Aplicar offset de ultimate
	
	# Activar estado de parry
	is_parrying = true
	parry_hit_received = false
	
	var parry_timer = 0.0
	var parry_duration = 2.0
	
	# Esperar 2 segundos o hasta ser golpeado
	while parry_timer < parry_duration and not parry_hit_received:
		await get_tree().create_timer(0.1).timeout
		parry_timer += 0.1
	
	is_parrying = false
	
	if parry_hit_received:
		# Animar el resto de frames ultra (más rápido que la animación normal)
		if ultimate_frames.size() > 1:
			for i in range(1, ultimate_frames.size()):
				sprite_node.texture = ultimate_frames[i]
				sprite_node.offset = Vector2(0, 0)  # Sin offset para frames de contra-ataque
				await get_tree().create_timer(0.08).timeout
		
		# Señal para devolver la pelota con 999 de daño
		ishmael_parry_success.emit()
	else:
		# No fue golpeado, resetear ulti
		reset_combo()
