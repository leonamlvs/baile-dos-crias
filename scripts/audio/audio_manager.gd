extends Node

signal gameplay_finished

var _gameplay_player: AudioStreamPlayer
var _gameplay_clock: SongClock


func _ready() -> void:
	_gameplay_player = AudioStreamPlayer.new()
	_gameplay_player.name = "GameplayPlayer"
	add_child(_gameplay_player)
	_gameplay_player.finished.connect(_on_gameplay_finished)
	_gameplay_clock = SongClock.new(AudioPlayerClockSource.new(_gameplay_player))


func start_gameplay(stream: AudioStream, from_ms: int = 0) -> Dictionary:
	if stream == null:
		return {"ok": false, "error": "Gameplay audio stream is required."}
	_gameplay_player.stream = stream
	return _gameplay_clock.start(from_ms)


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


func get_song_time_ms() -> int:
	return _gameplay_clock.get_time_ms()


func is_gameplay_finished() -> bool:
	return _gameplay_clock.is_finished()


func _on_gameplay_finished() -> void:
	gameplay_finished.emit()
