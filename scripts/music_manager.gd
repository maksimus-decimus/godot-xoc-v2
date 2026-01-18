extends Node

class_name MusicManagerClass

var music_player: AudioStreamPlayer

# Referencias a las canciones
const TITLE_MUSIC = "res://assets/msc/music/title.mp3"
const CHAR_SELECT_MUSIC = "res://assets/msc/music/char_select.mp3"
const STAGE_1_MUSIC = "res://assets/msc/music/stg_1.mp3"
const STAGE_2_MUSIC = "res://assets/msc/music/stg_2.mp3"  # Agrega tu archivo de música aquí
const STAGE_3_MUSIC = "res://assets/msc/music/stg_3.mp3"  # Agrega tu archivo de música aquí

# Función helper para obtener música del mapa
func get_stage_music(map_index: int) -> String:
	match map_index:
		0:
			return STAGE_1_MUSIC
		1:
			return STAGE_2_MUSIC
		2:
			return STAGE_3_MUSIC
		_:
			return STAGE_1_MUSIC

var current_track: String = ""

func _ready():
	# Crear el AudioStreamPlayer
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

func play_music(track_path: String):
	# Solo cambiar si es una canción diferente
	if current_track == track_path and music_player.playing:
		return
	
	current_track = track_path
	var stream = load(track_path)
	
	# Configurar loop según el tipo de archivo
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	music_player.stream = stream
	music_player.play()

func stop_music():
	music_player.stop()
	current_track = ""
