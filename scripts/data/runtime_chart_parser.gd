class_name RuntimeChartParser
extends RefCounted

const CHART_VERSION := 1


func parse_file(path: String, expected_song_id: String = "", expected_difficulty: String = "") -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("Chart file does not exist: %s" % path)
	return parse_text(FileAccess.get_file_as_string(path), expected_song_id, expected_difficulty)


func parse_text(text: String, expected_song_id: String = "", expected_difficulty: String = "") -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return _failure("Malformed chart JSON: %s" % json.get_error_message())
	if not json.data is Dictionary:
		return _failure("Chart root must be an object.")
	return validate(json.data, expected_song_id, expected_difficulty)


func validate(source: Dictionary, expected_song_id: String = "", expected_difficulty: String = "") -> Dictionary:
	var version_value: Variant = source.get("version", null)
	if not _is_integer_number(version_value):
		return _failure("Chart version must be an integer.")
	if int(version_value) != CHART_VERSION:
		return _failure("Unsupported chart version %d." % int(version_value))

	var song_id_value: Variant = source.get("song_id", null)
	if not song_id_value is String or not _is_stable_id(song_id_value):
		return _failure("song_id must be a stable lowercase kebab-case ID.")
	var song_id: String = song_id_value
	if not expected_song_id.is_empty() and song_id != expected_song_id:
		return _failure("Chart song_id '%s' does not match '%s'." % [song_id, expected_song_id])

	var difficulty_value: Variant = source.get("difficulty", null)
	if not difficulty_value is String or not _is_stable_id(difficulty_value):
		return _failure("difficulty must be a stable lowercase kebab-case ID.")
	var difficulty: String = difficulty_value
	if not expected_difficulty.is_empty() and difficulty != expected_difficulty:
		return _failure("Chart difficulty '%s' does not match '%s'." % [difficulty, expected_difficulty])

	var notes_value: Variant = source.get("notes", null)
	if not notes_value is Array:
		return _failure("notes must be an array.")
	if notes_value.is_empty():
		return _failure("notes must contain at least one note.")

	var notes: Array[Dictionary] = []
	var note_ids := {}
	var previous_time_ms := -1
	for index in notes_value.size():
		var note_value: Variant = notes_value[index]
		if not note_value is Dictionary:
			return _failure("notes[%d] must be an object." % index)
		var normalized := _validate_note(note_value, index)
		if not normalized.ok:
			return normalized
		var note: Dictionary = normalized.chart
		if note_ids.has(note.id):
			return _failure("Duplicate note ID '%s'." % note.id)
		note_ids[note.id] = true
		if int(note.time_ms) < previous_time_ms:
			return _failure("notes must be ordered by non-decreasing time_ms.")
		previous_time_ms = int(note.time_ms)
		notes.append(note)

	return {"ok": true, "error": "", "chart": {
		"version": CHART_VERSION,
		"song_id": song_id,
		"difficulty": difficulty,
		"notes": notes,
	}}


func _validate_note(source: Dictionary, index: int) -> Dictionary:
	var id_value: Variant = source.get("id", null)
	if not id_value is String or String(id_value).strip_edges().is_empty():
		return _failure("notes[%d].id must be a non-empty string." % index)
	var time_value: Variant = source.get("time_ms", null)
	if not _is_integer_number(time_value) or int(time_value) < 0:
		return _failure("notes[%d].time_ms must be a non-negative integer." % index)
	var pad_value: Variant = source.get("pad", null)
	if not _is_integer_number(pad_value) or int(pad_value) < 1 or int(pad_value) > 9:
		return _failure("notes[%d].pad must be an integer from 1 through 9." % index)
	var type_value: Variant = source.get("type", null)
	if type_value != "tap" and type_value != "hold":
		return _failure("notes[%d].type must be 'tap' or 'hold'." % index)

	var note := {
		"id": String(id_value),
		"time_ms": int(time_value),
		"pad": int(pad_value),
		"type": String(type_value),
	}
	if type_value == "tap":
		if source.has("end_ms") or source.has("ticks_ms"):
			return _failure("Tap notes must not define Hold-only fields.")
		return {"ok": true, "error": "", "chart": note}

	var end_value: Variant = source.get("end_ms", null)
	if not _is_integer_number(end_value) or int(end_value) <= int(time_value):
		return _failure("Hold end_ms must be an integer greater than time_ms.")
	var ticks_value: Variant = source.get("ticks_ms", null)
	if not ticks_value is Array:
		return _failure("Hold ticks_ms must be an array.")
	var ticks: Array[int] = []
	var previous_tick := -1
	for tick_index in ticks_value.size():
		var tick_value: Variant = ticks_value[tick_index]
		if not _is_integer_number(tick_value):
			return _failure("Hold ticks_ms[%d] must be an integer." % tick_index)
		var tick := int(tick_value)
		if tick <= int(time_value) or tick >= int(end_value):
			return _failure("Hold ticks must satisfy time_ms < tick_ms < end_ms.")
		if tick <= previous_tick:
			return _failure("Hold ticks_ms must be strictly increasing.")
		ticks.append(tick)
		previous_tick = tick
	note["end_ms"] = int(end_value)
	note["ticks_ms"] = ticks
	return {"ok": true, "error": "", "chart": note}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message, "chart": {}}


func _is_integer_number(value: Variant) -> bool:
	return value is int or (value is float and floor(value) == value)


func _is_stable_id(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[a-z0-9]+(?:-[a-z0-9]+)*$")
	return regex.search(value) != null
