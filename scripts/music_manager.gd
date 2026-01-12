extends Node

class_name MusicManagerClass

var music_player: AudioStreamPlayer

# Referencias a las canciones
const TITLE_MUSIC = "res://assets/msc/music/title.mp3"
const CHAR_SELECT_MUSIC = "res://assets/msc/music/char_select.mp3"
const STAGE_MUSIC = "res://assets/msc/music/stg_1.mp3"

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
	music_player.stream = stream
	music_player.play()

func stop_music():
	music_player.stop()
	current_track = ""
