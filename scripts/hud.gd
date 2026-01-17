extends Control

@onready var p1_hp_bar = $HPBar
@onready var p1_hp_label = $P1Section/HPLabel
@onready var p1_lives_label = $P1Section/LivesLabel
@onready var p1_combo_label = $P1Section/ComboLabel

@onready var p2_hp_bar = $HPBar2
@onready var p2_hp_label = $P2Section/HPLabel
@onready var p2_lives_label = $P2Section/LivesLabel
@onready var p2_combo_label = $P2Section/ComboLabel

@onready var ball_speed_label = $MarginContainer/VBoxContainer/BallSpeedLabel

# Portraits de personajes
@onready var don_port_l = $DonHudPort_L
@onready var don_port_r = $DonHudPort_R
@onready var ishm_port_l = $IshmHudPort_L
@onready var ishm_port_r = $IshmHudPort_R

func _ready() -> void:
	p1_hp_bar.max_value = Global.MAX_HP
	p2_hp_bar.max_value = Global.MAX_HP
	
	# Mostrar portraits según el personaje de cada jugador
	setup_portraits()

func update_hp(player_id: int, current_hp: float, max_hp: float) -> void:
	if player_id == 1:
		p1_hp_bar.value = current_hp
		p1_hp_label.text = "HP: %d/%d" % [current_hp, max_hp]
		update_hp_color(p1_hp_bar, current_hp, max_hp)
	else:
		p2_hp_bar.value = current_hp
		p2_hp_label.text = "HP: %d/%d" % [current_hp, max_hp]
		update_hp_color(p2_hp_bar, current_hp, max_hp)

func update_hp_color(bar: ProgressBar, current: float, maximum: float) -> void:
	var percentage = current / maximum
	
	if percentage > 0.6:
		bar.modulate = Color.GREEN
	elif percentage > 0.3:
		bar.modulate = Color.YELLOW
	else:
		bar.modulate = Color.RED

func update_lives(player_id: int, lives: int) -> void:
	var hearts = ""
	for i in range(lives):
		hearts += "♥ "
	
	if player_id == 1:
		p1_lives_label.text = "Vidas: " + hearts
	else:
		p2_lives_label.text = "Vidas: " + hearts

func update_ball_speed(speed: float) -> void:
	ball_speed_label.text = "Velocidad Bola: %d px/s" % speed

func update_combo(player_id: int, combo: int) -> void:
	var combo_text = ""
	if combo >= 4:
		combo_text = "¡ULTRA LISTA!"
	else:
		combo_text = "Combo: %d/4" % combo
	
	if player_id == 1:
		p1_combo_label.text = combo_text
		if combo >= 4:
			p1_combo_label.modulate = Color.GOLD
		else:
			p1_combo_label.modulate = Color.WHITE
	else:
		p2_combo_label.text = combo_text
		if combo >= 4:
			p2_combo_label.modulate = Color.GOLD
		else:
			p2_combo_label.modulate = Color.WHITE

func setup_portraits() -> void:
	# Ocultar todos los portraits primero
	don_port_l.visible = false
	don_port_r.visible = false
	ishm_port_l.visible = false
	ishm_port_r.visible = false
	
	# Mostrar portrait del jugador 1 (lado izquierdo)
	if Global.player1_character == 0:  # Don Quixote
		don_port_l.visible = true
	else:  # Ishmael
		ishm_port_l.visible = true
	
	# Mostrar portrait del jugador 2 (lado derecho)
	if Global.player2_character == 0:  # Don Quixote
		don_port_r.visible = true
	else:  # Ishmael
		ishm_port_r.visible = true

func shake_portrait(player_id: int) -> void:
	var portrait: Sprite2D
	
	# Determinar cuál portrait vibrar según el jugador y su personaje
	if player_id == 1:
		if Global.player1_character == 0:
			portrait = don_port_l
		else:
			portrait = ishm_port_l
	else:
		if Global.player2_character == 0:
			portrait = don_port_r
		else:
			portrait = ishm_port_r
	
	if not portrait:
		return
	
	var original_position = portrait.position
	var shake_amount = 8.0
	var shake_duration = 0.3
	var shake_time = 0.0
	
	# Vibrar durante un tiempo corto
	while shake_time < shake_duration:
		portrait.position = original_position + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		await get_tree().create_timer(0.05).timeout
		shake_time += 0.05
	
	# Restaurar posición original
	portrait.position = original_position
