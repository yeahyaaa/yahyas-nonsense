extends Node
## AudioManager - Handles all game audio

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 8

var music_volume: float = 0.8
var sfx_volume: float = 1.0
var music_enabled: bool = true
var sfx_enabled: bool = true

func _ready() -> void:
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# Create SFX player pool
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play_music(stream: AudioStream, fade_in: float = 1.0) -> void:
	if not music_enabled:
		return

	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -40, 0.5)
		await tween.finished

	music_player.stream = stream
	music_player.volume_db = -40
	music_player.play()

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_in)

func stop_music(fade_out: float = 1.0) -> void:
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -40, fade_out)
		await tween.finished
		music_player.stop()

func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> void:
	if not sfx_enabled:
		return

	# Find available player
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume)
			if pitch_variation > 0:
				player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
			else:
				player.pitch_scale = 1.0
			player.play()
			return

	# All players busy, use the first one (interrupt)
	sfx_players[0].stream = stream
	sfx_players[0].play()

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

func toggle_music(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled:
		music_player.stop()

func toggle_sfx(enabled: bool) -> void:
	sfx_enabled = enabled
