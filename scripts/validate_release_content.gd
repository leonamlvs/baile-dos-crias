extends SceneTree

const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const RuntimeChartParserScript = preload("res://scripts/data/runtime_chart_parser.gd")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = ContentCatalogScript.new()
	catalog.load_from_root("res://content")
	for diagnostic in catalog.diagnostics:
		_errors.append("%s: %s" % [diagnostic.path, diagnostic.message])
	if catalog.characters.is_empty():
		_errors.append("MVP release requires at least one valid character.")
	if catalog.tables.is_empty():
		_errors.append("MVP release requires at least one valid DJ table.")
	if catalog.songs.is_empty():
		_errors.append("MVP release requires at least one cleared playable song.")

	for song in catalog.songs:
		var difficulties: Array = song.difficulties
		for required in ["easy", "normal"]:
			if not difficulties.has(required):
				_errors.append("Song '%s' is missing MVP difficulty '%s'." % [song.id, required])
		for difficulty_value in difficulties:
			var difficulty := String(difficulty_value)
			var chart_path := String(song.content_path).path_join("charts").path_join("%s.json" % difficulty)
			var parsed: Dictionary = RuntimeChartParserScript.new().parse_file(chart_path, String(song.id), difficulty)
			if not parsed.ok:
				_errors.append("%s: %s" % [chart_path, parsed.error])

	if _errors.is_empty():
		print("Release content validation passed: %d song(s), %d character(s), %d table(s)." % [
			catalog.songs.size(), catalog.characters.size(), catalog.tables.size(),
		])
		quit(0)
		return
	for error in _errors:
		printerr("RELEASE BLOCKER: %s" % error)
	printerr("Release content validation failed with %d blocker(s)." % _errors.size())
	quit(1)
