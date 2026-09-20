class_name ContentValidator
extends RefCounted


static func load_song_audio(song: Dictionary) -> Dictionary:
	var content_path := String(song.get("content_path", ""))
	var audio_path := String(song.get("audio", ""))
	var resource_path := content_path.path_join(audio_path)
	var stream := load(resource_path) as AudioStream
	if stream == null:
		return _failure("Song audio is not a loadable AudioStream: %s" % resource_path)
	var length_seconds := stream.get_length()
	if not is_finite(length_seconds) or length_seconds <= 0.0:
		return _failure("Song audio must have a finite positive duration: %s" % resource_path)
	return {
		"ok": true,
		"error": "",
		"stream": stream,
		"audio_duration_ms": int(floor(length_seconds * 1000.0)),
	}


static func validate_song_audio(song: Dictionary) -> Dictionary:
	var loaded := load_song_audio(song)
	if not loaded.ok:
		return loaded
	var metadata_duration_ms := int(song.get("duration_ms", 0))
	var preview_start_ms := int(song.get("preview_start_ms", 0))
	if preview_start_ms >= metadata_duration_ms:
		return _failure("preview_start_ms must be before duration_ms.")
	if preview_start_ms >= int(loaded.audio_duration_ms):
		return _failure("preview_start_ms must be before the decoded audio end.")
	return loaded


static func validate_chart_duration(chart: Dictionary, song: Dictionary, audio_duration_ms: int) -> Dictionary:
	var metadata_duration_ms := int(song.get("duration_ms", 0))
	var endpoint_ms := mini(metadata_duration_ms, audio_duration_ms)
	for note_value in chart.get("notes", []):
		var note: Dictionary = note_value
		if int(note.time_ms) >= endpoint_ms:
			return _failure("Note '%s' starts at or after the song endpoint (%d ms)." % [note.id, endpoint_ms])
		if note.type == "hold" and int(note.end_ms) > endpoint_ms:
			return _failure("Hold '%s' ends after the song endpoint (%d ms)." % [note.id, endpoint_ms])
	return {"ok": true, "error": ""}


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
