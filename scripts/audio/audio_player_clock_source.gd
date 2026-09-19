class_name AudioPlayerClockSource
extends RefCounted

var _player: AudioStreamPlayer


func _init(player: AudioStreamPlayer) -> void:
	_player = player


func play(from_seconds: float = 0.0) -> void:
	_player.play(from_seconds)


func stop() -> void:
	_player.stop()


func is_playing() -> bool:
	return _player.playing


func get_position_seconds() -> float:
	return _player.get_playback_position()


func set_paused(paused: bool) -> void:
	_player.stream_paused = paused


func is_paused() -> bool:
	return _player.stream_paused


func get_mix_delta_seconds() -> float:
	return AudioServer.get_time_since_last_mix()


func get_output_latency_seconds() -> float:
	return AudioServer.get_output_latency()
