extends SceneTree

const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const ContentValidatorScript = preload("res://scripts/data/content_validator.gd")
const RuntimeChartParserScript = preload("res://scripts/data/runtime_chart_parser.gd")
const ReleaseInventoryScript = preload("res://scripts/data/release_inventory.gd")

const RELEASE_INVENTORY_PATH := "res://content/release-content.json"
const START_AUDIO_PATH := "res://assets/ref/audio/BASE DE FUNK 150 BPM  INSTRUMENTAL  USO LIVRE 03 Prod DIL34N.mp3"

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var inventory := _load_release_inventory()
	var inventory_entries := _validate_release_inventory(inventory)
	_validate_inventoried_release_files(inventory_entries)
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
	_require_cleared_entry(START_AUDIO_PATH, "start_audio", inventory_entries)

	for song in catalog.songs:
		var audio_validation: Dictionary = ContentValidatorScript.validate_song_audio(song)
		if not audio_validation.ok:
			_errors.append("%s: %s" % [song.content_path, audio_validation.error])
		_require_cleared_entry(
			String(song.content_path).path_join(String(song.audio)),
			"song_audio",
			inventory_entries,
		)
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
			else:
				if audio_validation.ok:
					var duration_validation: Dictionary = ContentValidatorScript.validate_chart_duration(
						parsed.chart,
						song,
						int(audio_validation.audio_duration_ms),
					)
					if not duration_validation.ok:
						_errors.append("%s: %s" % [chart_path, duration_validation.error])
			_require_cleared_entry(chart_path, "chart", inventory_entries)

	for character in catalog.characters:
		_require_optional_visual(character, "visual", "character_visual", inventory_entries)
	for table in catalog.tables:
		_require_optional_visual(table, "visual", "table_visual", inventory_entries)

	if _errors.is_empty():
		print("Release content validation passed: %d song(s), %d character(s), %d table(s)." % [
			catalog.songs.size(), catalog.characters.size(), catalog.tables.size(),
		])
		quit(0)
		return
	var unique_errors: Array[String] = []
	for error in _errors:
		if not unique_errors.has(error):
			unique_errors.append(error)
	for error in unique_errors:
		printerr("RELEASE BLOCKER: %s" % error)
	printerr("Release content validation failed with %d blocker(s)." % unique_errors.size())
	quit(1)


func _load_release_inventory() -> Dictionary:
	if not FileAccess.file_exists(RELEASE_INVENTORY_PATH):
		_errors.append("Missing release content inventory: %s" % RELEASE_INVENTORY_PATH)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(RELEASE_INVENTORY_PATH)) != OK or not json.data is Dictionary:
		_errors.append("Release content inventory must be valid JSON with an object root.")
		return {}
	return json.data


func _validate_release_inventory(inventory: Dictionary) -> Dictionary:
	if inventory.is_empty():
		return {}
	var inspected: Dictionary = ReleaseInventoryScript.inspect(inventory)
	_errors.append_array(inspected.errors)
	var indexed: Dictionary = inspected.entries
	for resource_path_variant in indexed:
		var resource_path := String(resource_path_variant)
		var entry: Dictionary = indexed[resource_path]
		if bool(entry.get("include_in_release", false)) and not FileAccess.file_exists(resource_path):
			_errors.append("Inventoried release file is missing: %s" % resource_path)
	return indexed


func _require_cleared_entry(resource_path: String, expected_kind: String, entries: Dictionary) -> void:
	_errors.append_array(ReleaseInventoryScript.required_entry_errors(entries, resource_path, expected_kind))


func _require_optional_visual(item: Dictionary, field: String, kind: String, entries: Dictionary) -> void:
	var relative_path := String(item.get(field, ""))
	if relative_path.is_empty():
		return
	_require_cleared_entry(String(item.content_path).path_join(relative_path), kind, entries)


func _validate_inventoried_release_files(entries: Dictionary) -> void:
	_scan_release_files("res://assets/ref/audio", entries)
	_scan_release_files("res://content", entries)


func _scan_release_files(directory_path: String, entries: Dictionary) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	for filename in directory.get_files():
		var resource_path := directory_path.path_join(filename)
		if filename == "metadata.json" or resource_path == RELEASE_INVENTORY_PATH:
			continue
		if resource_path.begins_with("res://assets/ref/audio/DJ"):
			continue
		var extension := filename.get_extension().to_lower()
		if extension not in ["mp3", "ogg", "wav", "json", "png", "jpg", "jpeg", "webp", "svg"]:
			continue
		if not entries.has(resource_path):
			_errors.append("Potential release content is not inventoried: %s" % resource_path)
			continue
		var entry: Dictionary = entries[resource_path]
		_require_cleared_entry(resource_path, String(entry.get("kind", "")), entries)
	for child_directory in directory.get_directories():
		if directory_path.begins_with("res://content/songs/") and child_directory == "source":
			continue
		_scan_release_files(directory_path.path_join(child_directory), entries)
