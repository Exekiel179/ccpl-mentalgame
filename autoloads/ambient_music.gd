## AmbientMusic — procedural ambient music via AudioStreamGenerator,
## OR plays MP3 background tracks.
extends Node

const SAMPLE_RATE := 44100.0
const VOLUME_DB := -14.0
const PRESETS: Array[Dictionary] = [
	{
		"freqs": [130.81, 146.83, 164.81, 196.00, 220.00],
		"harmonic": 0.30,
		"gain": 0.12,
		"drift_min": 1.4,
		"drift_max": 2.0,
	},
	{
		"freqs": [110.00, 130.81, 146.83, 174.61, 196.00],
		"harmonic": 0.22,
		"gain": 0.10,
		"drift_min": 1.8,
		"drift_max": 2.6,
	},
	{
		"freqs": [164.81, 196.00, 220.00, 261.63, 293.66],
		"harmonic": 0.36,
		"gain": 0.09,
		"drift_min": 1.2,
		"drift_max": 1.8,
	},
	{
		"freqs": [98.00, 130.81, 155.56, 174.61, 207.65],
		"harmonic": 0.18,
		"gain": 0.11,
		"drift_min": 2.0,
		"drift_max": 3.0,
	},
]

enum Track { PROCEDURAL, MENU, CARD_GAME, MAZE_GAME }

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _gen_stream: AudioStreamGenerator
var _phase1: float = 0.0
var _phase2: float = 0.0
var _current_freq: float = 130.81
var _note_idx: int = 0
var _note_timer: float = 0.0
var _playing: bool = false
var _is_procedural: bool = true
var _freqs: Array = []
var _harmonic_ratio: float = 0.3
var _gain: float = 0.12
var _drift_min: float = 1.4
var _drift_max: float = 2.0

var _tracks: Dictionary = {
	Track.MENU: preload("res://assets/music/Chrono_Drift.mp3"),
	Track.CARD_GAME: preload("res://assets/music/Harmonic_Drift.mp3"),
	Track.MAZE_GAME: preload("res://assets/music/Harmonic_Drift.mp3") # Placeholder if only 2 tracks exist
}

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_gen_stream = AudioStreamGenerator.new()
	_gen_stream.mix_rate = SAMPLE_RATE
	_gen_stream.buffer_length = 0.3
	_player.volume_db = VOLUME_DB
	add_child(_player)
	
	for track in _tracks.values():
		if track is AudioStreamMP3:
			track.loop = true

func is_playing() -> bool:
	return _playing

var _last_track: Track = Track.PROCEDURAL

func start(track_type: int = -1) -> void:
	if track_type == -1:
		track_type = _last_track
	else:
		_last_track = track_type
	
	if _playing:
		stop()
	
	if track_type == Track.PROCEDURAL:
		_is_procedural = true
		_player.stream = _gen_stream
		_pick_preset()
		_player.play()
		_playback = _player.get_stream_playback()
		_note_timer = 0.0
	else:
		_is_procedural = false
		_player.stream = _tracks.get(track_type)
		_player.play()
		_playback = null
	
	_playing = true

func stop() -> void:
	_playing = false
	_player.stop()
	_playback = null

func _pick_preset() -> void:
	var preset: Dictionary = PRESETS[randi() % PRESETS.size()]
	_freqs = preset.get("freqs", []).duplicate()
	_harmonic_ratio = float(preset.get("harmonic", 0.3))
	_gain = float(preset.get("gain", 0.12))
	_drift_min = float(preset.get("drift_min", 1.4))
	_drift_max = float(preset.get("drift_max", 2.0))
	_note_idx = randi() % _freqs.size()
	_current_freq = float(_freqs[_note_idx])
	_phase1 = randf()
	_phase2 = randf()

func _process(delta: float) -> void:
	if not _playing or not _is_procedural or _playback == null:
		return
	_note_timer -= delta
	if _note_timer <= 0.0:
		_note_idx = (_note_idx + 1) % _freqs.size()
		_current_freq = float(_freqs[_note_idx])
		_note_timer = randf_range(_drift_min, _drift_max)
	var frames := _playback.get_frames_available()
	var inv_sr := 1.0 / SAMPLE_RATE
	for i in frames:
		var s := sin(_phase1 * TAU) * _gain + sin(_phase2 * TAU) * (_gain * _harmonic_ratio)
		_phase1 += _current_freq * inv_sr
		_phase2 += _current_freq * 2.0 * inv_sr
		if _phase1 >= 1.0:
			_phase1 -= 1.0
		if _phase2 >= 1.0:
			_phase2 -= 1.0
		_playback.push_frame(Vector2(s, s))
