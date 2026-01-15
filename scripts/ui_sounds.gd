extends Node

class_name UISoundsClass

var audio_player: AudioStreamPlayer

# Referencias a sonidos
const SLIDE_SOUNDS = [
	"res://sound/sfx/menu_sounds/selectslide.p1.2.wav",
	"res://sound/sfx/menu_sounds/selectslide.p2.2.wav"
]

const SELECT_SOUND = "res://sound/sfx/menu_sounds/menu.select.wav"
const CANCEL_SOUND = "res://sound/sfx/menu_sounds/ui.nope.wav"

# Pool para alternancia sin repetición inmediata
var last_slide_index: int = -1

func _ready():
	# Crear el AudioStreamPlayer
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

# Sonido cuando navegas por el menú (W/S/A/D)
func play_slide():
	# Alternar entre los dos sonidos de slide
	var new_index = (last_slide_index + 1) % SLIDE_SOUNDS.size()
	last_slide_index = new_index
	
	audio_player.stream = load(SLIDE_SOUNDS[new_index])
	audio_player.play()

# Sonido cuando confirmas una selección (espacio/click)
func play_select():
	audio_player.stream = load(SELECT_SOUND)
	audio_player.play()

# Sonido cuando cancelas o vuelves atrás (ESC)
func play_cancel():
	audio_player.stream = load(CANCEL_SOUND)
	audio_player.play()
