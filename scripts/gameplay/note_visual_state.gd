class_name NoteVisualState
extends RefCounted


static func approach_progress(song_time_ms: int, hit_time_ms: int, approach_ms: int) -> float:
	if approach_ms <= 0:
		return 1.0 if song_time_ms >= hit_time_ms else 0.0
	return clampf(
		float(song_time_ms - (hit_time_ms - approach_ms)) / float(approach_ms),
		0.0,
		1.0,
	)


static func hold_progress(song_time_ms: int, hit_time_ms: int, end_time_ms: int) -> float:
	if end_time_ms <= hit_time_ms:
		return 1.0
	return clampf(
		float(song_time_ms - hit_time_ms) / float(end_time_ms - hit_time_ms),
		0.0,
		1.0,
	)
