extends Node

signal gameplay_finished

var _gameplay_player: AudioStreamPlayer
var _gameplay_clock: SongClock
var _preview_player: AudioStreamPlayer
var _preview_start_ms := 0
var _preview_started_at_ms := 0
var _preview_duration_ms := 15000
var _preview_fade_ms := 250
var _master_volume := 1.0


func _ready() -> void:
	_gameplay_player = AudioStreamPlayer.new()
	_gameplay_player.name = "GameplayPlayer"
	add_child(_gameplay_player)
	_gameplay_player.finished.connect(_on_gameplay_finished)
	_gameplay_clock = SongClock.new(AudioPlayerClockSource.new(_gameplay_player))
	_preview_player = AudioStreamPlayer.new()
	_preview_player.name = "PreviewPlayer"
	add_child(_preview_player)
	set_master_volume(SaveManager.get_master_volume())


func start_gameplay(stream: AudioStream, from_ms: int = 0) -> Dictionary:
	if stream == null:
		return {"ok": false, "error": "Gameplay audio stream is required."}
	_gameplay_player.stream = stream
	_gameplay_player.volume_db = linear_to_db(maxf(0.0001, _master_volume))
	return _gameplay_clock.start(from_ms)


func set_master_volume(volume: float) -> bool:
	if is_nan(volume) or is_inf(volume) or volume < 0.0 or volume > 1.0:
		return false
	_master_volume = volume
	_gameplay_player.volume_db = linear_to_db(maxf(0.0001, _master_volume)) if _gameplay_player != null else -80.0
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


func _process(_delta: float) -> void:
	if not _preview_player.playing:
		return
	var elapsed_ms := Time.get_ticks_msec() - _preview_started_at_ms
	if elapsed_ms >= _preview_duration_ms:
		_preview_started_at_ms = Time.get_ticks_msec()
		_preview_player.play(float(_preview_start_ms) / 1000.0)
		elapsed_ms = 0
	var fade := 1.0
	if _preview_fade_ms > 0:
		if elapsed_ms < _preview_fade_ms:
			fade = float(elapsed_ms) / float(_preview_fade_ms)
		elif elapsed_ms > _preview_duration_ms - _preview_fade_ms:
			fade = float(_preview_duration_ms - elapsed_ms) / float(_preview_fade_ms)
	_preview_player.volume_db = linear_to_db(maxf(0.0001, fade * _master_volume))
