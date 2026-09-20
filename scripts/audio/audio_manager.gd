extends Node

signal gameplay_finished

var _start_player: AudioStreamPlayer
var _gameplay_player: AudioStreamPlayer
var _gameplay_clock: SongClock
var _preview_player: AudioStreamPlayer
var _preview_start_ms := 0
var _preview_started_at_ms := 0
var _preview_duration_ms := 15000
var _preview_fade_ms := 250
var _master_volume := 1.0


func _ready() -> void:
	_start_player = AudioStreamPlayer.new()
	_start_player.name = "StartPlayer"
	add_child(_start_player)
	_start_player.finished.connect(_on_start_music_finished)
	_gameplay_player = AudioStreamPlayer.new()
	_gameplay_player.name = "GameplayPlayer"
	add_child(_gameplay_player)
	_gameplay_player.finished.connect(_on_gameplay_finished)
	_gameplay_clock = SongClock.new(AudioPlayerClockSource.new(_gameplay_player))
	_preview_player = AudioStreamPlayer.new()
	_preview_player.name = "PreviewPlayer"
	add_child(_preview_player)
	set_master_volume(SaveManager.get_master_volume())


func start_start_music(stream: AudioStream) -> Dictionary:
	if stream == null:
		return {"ok": false, "error": "Start-screen audio stream is required."}
	stop_preview()
	_start_player.stop()
	_start_player.stream = stream
	_start_player.volume_db = _volume_db(_master_volume)
	_start_player.play()
	return {"ok": true, "error": ""}


func stop_start_music() -> void:
	_start_player.stop()
	_start_player.stream = null


func is_start_music_playing() -> bool:
	return _start_player != null and _start_player.playing


func get_start_beat_phase(bpm: float = 150.0, offset_ms: int = 0) -> float:
	if _start_player == null or not _start_player.playing:
		return 0.0
	return beat_phase_at(int(round(_start_player.get_playback_position() * 1000.0)), bpm, offset_ms)


func start_gameplay(stream: AudioStream, from_ms: int = 0) -> Dictionary:
	if stream == null:
		return {"ok": false, "error": "Gameplay audio stream is required."}
	stop_start_music()
	stop_preview()
	_gameplay_player.stream = stream
	_gameplay_player.volume_db = _volume_db(_master_volume)
	return _gameplay_clock.start(from_ms)


func set_master_volume(volume: float) -> bool:
	if is_nan(volume) or is_inf(volume) or volume < 0.0 or volume > 1.0:
		return false
	_master_volume = volume
	if _start_player != null:
		_start_player.volume_db = _volume_db(_master_volume)
	if _gameplay_player != null:
		_gameplay_player.volume_db = _volume_db(_master_volume)
	if _preview_player != null:
		_preview_player.volume_db = _volume_db(_master_volume)
	return true


func get_master_volume() -> float:
	return _master_volume


func pause_gameplay() -> int:
	return _gameplay_clock.pause()


func resume_gameplay() -> Dictionary:
	return _gameplay_clock.resume()


func retry_gameplay() -> Dictionary:
	if _gameplay_player.stream == null:
		return {"ok": false, "error": "No gameplay stream is loaded."}
	return _gameplay_clock.retry()


func stop_gameplay() -> void:
	_gameplay_clock.stop()
	_gameplay_player.stream = null


func start_preview(stream: AudioStream, start_ms: int = 0, duration_ms: int = 15000, fade_ms: int = 250) -> Dictionary:
	if stream == null:
		return {"ok": false, "error": "Preview audio stream is required."}
	if start_ms < 0 or duration_ms <= 0 or fade_ms < 0 or fade_ms * 2 > duration_ms:
		return {"ok": false, "error": "Preview timing values are invalid."}
	stop_start_music()
	_preview_player.stop()
	_preview_player.stream = stream
	_preview_start_ms = start_ms
	_preview_duration_ms = duration_ms
	_preview_fade_ms = fade_ms
	_preview_started_at_ms = Time.get_ticks_msec()
	_preview_player.volume_db = -80.0
	_preview_player.play(float(start_ms) / 1000.0)
	return {"ok": true, "error": ""}


func stop_preview() -> void:
	_preview_player.stop()
	_preview_player.stream = null


func is_preview_playing() -> bool:
	return _preview_player.playing


func get_song_time_ms() -> int:
	return _gameplay_clock.get_time_ms()


func is_gameplay_finished() -> bool:
	return _gameplay_clock.is_finished()


func _on_gameplay_finished() -> void:
	gameplay_finished.emit()


func _on_start_music_finished() -> void:
	if _start_player.stream != null:
		_start_player.play()


func _process(_delta: float) -> void:
	if _preview_player.stream == null:
		return
	var elapsed_ms := Time.get_ticks_msec() - _preview_started_at_ms
	if elapsed_ms >= _preview_duration_ms or not _preview_player.playing:
		_preview_started_at_ms = Time.get_ticks_msec()
		_preview_player.play(float(_preview_start_ms) / 1000.0)
		elapsed_ms = 0
	var fade := preview_gain_at(elapsed_ms, _preview_duration_ms, _preview_fade_ms)
	_preview_player.volume_db = _volume_db(fade * _master_volume)


static func beat_phase_at(time_ms: int, bpm: float = 150.0, offset_ms: int = 0) -> float:
	if bpm <= 0.0:
		return 0.0
	var beat_ms := 60000.0 / bpm
	return fposmod(float(time_ms - offset_ms), beat_ms) / beat_ms


static func preview_gain_at(elapsed_ms: int, duration_ms: int = 15000, fade_ms: int = 250) -> float:
	if duration_ms <= 0 or elapsed_ms < 0 or elapsed_ms >= duration_ms:
		return 0.0
	if fade_ms <= 0:
		return 1.0
	var bounded_fade := mini(fade_ms, duration_ms / 2)
	return clampf(minf(
		float(elapsed_ms) / float(bounded_fade),
		float(duration_ms - elapsed_ms) / float(bounded_fade),
	), 0.0, 1.0)


func _volume_db(linear: float) -> float:
	return -80.0 if linear <= 0.0 else linear_to_db(linear)
