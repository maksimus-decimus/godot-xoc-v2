extends Control

@onready var p1_hp_bar = $MarginContainer/VBoxContainer/TopBar/P1Section/HPBar
@onready var p1_hp_label = $MarginContainer/VBoxContainer/TopBar/P1Section/HPLabel
@onready var p1_lives_label = $MarginContainer/VBoxContainer/TopBar/P1Section/LivesLabel
@onready var p1_combo_label = $MarginContainer/VBoxContainer/TopBar/P1Section/ComboLabel

@onready var p2_hp_bar = $MarginContainer/VBoxContainer/TopBar/P2Section/HPBar
@onready var p2_hp_label = $MarginContainer/VBoxContainer/TopBar/P2Section/HPLabel
@onready var p2_lives_label = $MarginContainer/VBoxContainer/TopBar/P2Section/LivesLabel
@onready var p2_combo_label = $MarginContainer/VBoxContainer/TopBar/P2Section/ComboLabel

@onready var ball_speed_label = $MarginContainer/VBoxContainer/BallSpeedLabel

func _ready() -> void:
	p1_hp_bar.max_value = Global.MAX_HP
	p2_hp_bar.max_value = Global.MAX_HP

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
