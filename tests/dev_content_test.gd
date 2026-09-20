extends SceneTree

const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const ContentValidatorScript = preload("res://scripts/data/content_validator.gd")
const RuntimeChartParserScript = preload("res://scripts/data/runtime_chart_parser.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = ContentCatalogScript.new()
	catalog.load_from_root("res://content")
	var character := _find(catalog.characters, "dev-test-character")
	var table := _find(catalog.tables, "dev-test-table")
	var song := _find(catalog.songs, "dev-test-song")
	_check(not character.is_empty(), "test character appears in the local catalog")
	_check(not table.is_empty(), "test table appears in the local catalog")
	_check(not song.is_empty(), "test song appears in the local catalog")
	_check(not character.has("visual"), "test character uses the PresentationSlot fallback")
	_check(not table.has("visual"), "test table uses the PresentationSlot fallback")
	_check(song.get("difficulties", []) == ["easy", "normal"], "Easy and Normal appear")

	if not song.is_empty():
		var audio: Dictionary = ContentValidatorScript.validate_song_audio(song)
		_check(audio.ok, "test audio loads")
		if audio.ok:
			_check(abs(int(audio.audio_duration_ms) - 24000) <= 1, "test audio is 24 seconds")
		_validate_chart(song, "easy", 12, false)
		_validate_chart(song, "normal", 25, true)

	var export_preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	for excluded_path in [
		"content/characters/dev-test-character/*",
		"content/tables/dev-test-table/*",
		"content/songs/dev-test-song/*",
	]:
		_check(export_preset.contains(excluded_path), "Web export excludes %s" % excluded_path)

	if _failures.is_empty():
		print("DEV CONTENT TEST PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr("DEV CONTENT TEST FAILED: %s" % failure)
	quit(1)


func _validate_chart(song: Dictionary, difficulty: String, expected_count: int, require_overlap: bool) -> void:
	var path := String(song.content_path).path_join("charts/%s.json" % difficulty)
	var parsed: Dictionary = RuntimeChartParserScript.new().parse_file(path, String(song.id), difficulty)
	_check(parsed.ok, "%s chart parses" % difficulty)
	if not parsed.ok:
		return
	var notes: Array = parsed.chart.notes
	_check(notes.size() == expected_count, "%s chart has %d notes" % [difficulty, expected_count])
	var audio: Dictionary = ContentValidatorScript.validate_song_audio(song)
	if audio.ok:
		_check(
			ContentValidatorScript.validate_chart_duration(parsed.chart, song, int(audio.audio_duration_ms)).ok,
			"%s timestamps fit inside the audio" % difficulty,
		)
	var has_hold := false
	var has_ticks := false
	var has_chord := false
	var has_hold_tap_overlap := false
	var starts := {}
	var holds: Array[Dictionary] = []
	for note_value in notes:
		var note: Dictionary = note_value
		if starts.has(note.time_ms):
			has_chord = true
		starts[note.time_ms] = true
		if note.type == "hold":
			has_hold = true
			has_ticks = has_ticks or not note.ticks_ms.is_empty()
			holds.append(note)
	for note_value in notes:
		var note: Dictionary = note_value
		if note.type != "tap":
			continue
		for hold in holds:
			if int(note.time_ms) > int(hold.time_ms) and int(note.time_ms) < int(hold.end_ms):
				has_hold_tap_overlap = true
	_check(has_hold, "%s chart contains a Hold" % difficulty)
	_check(has_chord, "%s chart contains a chord" % difficulty)
	if difficulty == "normal":
		_check(has_ticks, "normal Hold contains ticks")
		_check(has_hold_tap_overlap, "normal contains Hold+Tap overlap")
		_check(require_overlap, "normal overlap requirement is enabled")


func _find(items: Array[Dictionary], id: String) -> Dictionary:
	for item in items:
		if item.get("id", "") == id:
			return item
	return {}


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
