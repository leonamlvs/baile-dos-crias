class_name ContentCatalog
extends RefCounted

const CATEGORY_SONG := "songs"
const CATEGORY_CHARACTER := "characters"
const CATEGORY_TABLE := "tables"

var songs: Array[Dictionary] = []
var characters: Array[Dictionary] = []
var tables: Array[Dictionary] = []
var diagnostics: Array[Dictionary] = []

var _items_by_category := {}
var _invalid_ids_by_category := {}


func load_from_root(content_root: String = "res://content") -> void:
	songs.clear()
	characters.clear()
	tables.clear()
	diagnostics.clear()
	_items_by_category.clear()
	_invalid_ids_by_category.clear()

	_load_category(content_root.path_join(CATEGORY_SONG), CATEGORY_SONG)
	_load_category(content_root.path_join(CATEGORY_CHARACTER), CATEGORY_CHARACTER)
	_load_category(content_root.path_join(CATEGORY_TABLE), CATEGORY_TABLE)

	songs = _items_by_category.get(CATEGORY_SONG, [])
	characters = _items_by_category.get(CATEGORY_CHARACTER, [])
	tables = _items_by_category.get(CATEGORY_TABLE, [])


func get_item(category: String, id: String) -> Dictionary:
	var category_items: Array = _items_by_category.get(category, [])
	for item in category_items:
		if item.get("id", "") == id:
			return {"ok": true, "item": item, "error": ""}

	var invalid_ids: Dictionary = _invalid_ids_by_category.get(category, {})
	if invalid_ids.has(id):
		return {"ok": false, "item": {}, "error": "Content ID '%s' is invalid and excluded." % id}
	return {"ok": false, "item": {}, "error": "Content ID '%s' was not found." % id}


func _load_category(category_path: String, category: String) -> void:
	var category_items: Array[Dictionary] = []
	var ids := {}
	var invalid_ids := {}
	var directory := DirAccess.open(category_path)
	if directory == null:
		_add_diagnostic(category_path, "Content directory is unavailable.")
		_items_by_category[category] = category_items
		_invalid_ids_by_category[category] = invalid_ids
		return

	var folder_names: Array[String] = []
	for folder_name in directory.get_directories():
		folder_names.append(folder_name)
	folder_names.sort()

	for folder_name in folder_names:
		var metadata_path := category_path.path_join(folder_name).path_join("metadata.json")
		var parsed: Dictionary = _read_metadata(metadata_path)
		if not parsed.ok:
			_add_diagnostic(metadata_path, parsed.error)
			if parsed.id != "":
				invalid_ids[parsed.id] = true
			continue

		var metadata: Dictionary = parsed.data
		var validation_error: String = _validate_metadata(metadata, category, category_path.path_join(folder_name))
		var id := String(metadata.get("id", ""))
		if validation_error != "":
			_add_diagnostic(metadata_path, validation_error)
			if id != "":
				invalid_ids[id] = true
			continue
		if ids.has(id):
			_add_diagnostic(metadata_path, "Duplicate %s ID '%s'." % [category, id])
			invalid_ids[id] = true
			continue

		ids[id] = true
		metadata["content_path"] = category_path.path_join(folder_name)
		category_items.append(metadata)

	category_items.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.id) < String(right.id)
	)
	_items_by_category[category] = category_items
	_invalid_ids_by_category[category] = invalid_ids


func _read_metadata(metadata_path: String) -> Dictionary:
	if not FileAccess.file_exists(metadata_path):
		return {"ok": false, "id": "", "error": "Missing metadata.json."}
	var text := FileAccess.get_file_as_string(metadata_path)
	var json := JSON.new()
	if json.parse(text) != OK:
		return {"ok": false, "id": "", "error": "Malformed JSON: %s" % json.get_error_message()}
	if not json.data is Dictionary:
		return {"ok": false, "id": "", "error": "Metadata root must be an object."}
	var data: Dictionary = json.data
	return {"ok": true, "id": String(data.get("id", "")), "data": data, "error": ""}


func _validate_metadata(metadata: Dictionary, category: String, item_path: String) -> String:
	var id: Variant = metadata.get("id", null)
	if not id is String or not _is_stable_id(id):
		return "Metadata requires a stable lowercase kebab-case id."
	var display_text: Variant = metadata.get("name", metadata.get("title", ""))
	if not display_text is String:
		return "Metadata requires display text."

	if category != CATEGORY_SONG:
		if String(metadata.get("name", "")).strip_edges().is_empty():
			return "Metadata requires a non-empty name."
		var visual_error := _validate_optional_content_path(metadata, "visual", item_path)
		if not visual_error.is_empty():
			return visual_error
		return ""

	for field in ["title", "artist", "bpm_display", "audio"]:
		if not metadata.get(field, null) is String or String(metadata[field]).strip_edges().is_empty():
			return "Song metadata requires a non-empty %s." % field
	var duration_value: Variant = metadata.get("duration_ms", null)
	if not _is_integer_number(duration_value) or int(duration_value) <= 0:
		return "Song metadata requires a positive integer duration_ms."
	var preview_start_value: Variant = metadata.get("preview_start_ms", 0)
	if not _is_integer_number(preview_start_value) or int(preview_start_value) < 0:
		return "Song preview_start_ms must be a non-negative integer."
	if int(preview_start_value) >= int(duration_value):
		return "Song preview_start_ms must be before duration_ms."
	metadata["preview_start_ms"] = int(preview_start_value)
	if not metadata.get("difficulties", null) is Array or metadata.difficulties.is_empty():
		return "Song metadata requires a non-empty difficulties array."
	for difficulty in metadata.difficulties:
		if not difficulty is String or not _is_stable_id(difficulty):
			return "Song difficulties must use stable lowercase kebab-case IDs."
	var audio_path := String(metadata.audio)
	if audio_path.is_absolute_path() or audio_path.contains(".."):
		return "Song audio path must be relative and must not leave its content directory."
	if not FileAccess.file_exists(item_path.path_join(audio_path)):
		return "Song audio path does not exist: %s" % audio_path
	if load(item_path.path_join(audio_path)) as AudioStream == null:
		return "Song audio path is not a loadable AudioStream: %s" % audio_path
	return ""


func _validate_optional_content_path(metadata: Dictionary, field: String, item_path: String) -> String:
	if not metadata.has(field):
		return ""
	var path_value: Variant = metadata[field]
	if not path_value is String or String(path_value).strip_edges().is_empty():
		return "Optional %s must be a non-empty relative path when provided." % field
	var relative_path := String(path_value)
	if relative_path.is_absolute_path() or relative_path.contains(".."):
		return "Optional %s must not leave its content directory." % field
	if not FileAccess.file_exists(item_path.path_join(relative_path)):
		return "Optional %s does not exist: %s" % [field, relative_path]
	if load(item_path.path_join(relative_path)) as Texture2D == null:
		return "Optional %s is not a loadable texture: %s" % [field, relative_path]
	return ""


func _is_stable_id(value: String) -> bool:
	var regex: RegEx = RegEx.new()
	regex.compile("^[a-z0-9]+(?:-[a-z0-9]+)*$")
	return regex.search(value) != null


func _is_integer_number(value: Variant) -> bool:
	return value is int or (value is float and floor(value) == value)


func _add_diagnostic(path: String, message: String) -> void:
	diagnostics.append({"path": path, "message": message})
