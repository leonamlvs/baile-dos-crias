class_name SongClock
extends RefCounted

enum State {
	STOPPED,
	PLAYING,
	PAUSED,
}

var _source: Variant
var _state := State.STOPPED
var _last_time_ms := 0
var _paused_time_ms := 0


func _init(source: Variant = null) -> void:
	_source = source


func set_source(source: Variant) -> void:
	_source = source
	reset()


func start(from_ms: int = 0) -> Dictionary:
	if _source == null:
		return {"ok": false, "error": "SongClock has no playback source."}
	if from_ms < 0:
		return {"ok": false, "error": "Song start time cannot be negative."}
	_source.play(float(from_ms) / 1000.0)
	_state = State.PLAYING
	_last_time_ms = from_ms
	_paused_time_ms = from_ms
	return {"ok": true, "error": ""}


func pause() -> int:
	if _state != State.PLAYING:
		return get_time_ms()
	_paused_time_ms = get_time_ms()
	_source.set_paused(true)
	_state = State.PAUSED
	return _paused_time_ms


func resume() -> Dictionary:
	if _state != State.PAUSED:
		return {"ok": false, "error": "SongClock is not paused."}
	_source.set_paused(false)
	_state = State.PLAYING
	_last_time_ms = _paused_time_ms
	return {"ok": true, "error": ""}


func stop() -> void:
	if _source != null:
		_source.stop()
	_state = State.STOPPED
	_last_time_ms = 0
	_paused_time_ms = 0


func reset() -> void:
	stop()


func retry() -> Dictionary:
	stop()
	return start(0)


func get_time_ms() -> int:
	if _state == State.STOPPED:
		return 0
	if _state == State.PAUSED:
		return _paused_time_ms
	if not _source.is_playing():
		return _last_time_ms

	var compensated_seconds: float = (
		float(_source.get_position_seconds())
		+ float(_source.get_mix_delta_seconds())
		- float(_source.get_output_latency_seconds())
	)
	var sampled_ms: int = maxi(0, int(round(compensated_seconds * 1000.0)))
	_last_time_ms = maxi(_last_time_ms, sampled_ms)
	return _last_time_ms


func get_state() -> State:
	return _state


func is_finished() -> bool:
	return _state == State.PLAYING and not _source.is_playing()
