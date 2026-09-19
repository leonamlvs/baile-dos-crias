extends Node

const SAVE_FORMAT := "baile-dos-crias-save"
const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://baile-dos-crias-save-v1.json"

var diagnostics: Array[String] = []
var _store: Variant = null
var _save_path := DEFAULT_SAVE_PATH
var _data := _default_data()
var _pending_import := {}
var _pending_import_counter := 0


func _ready() -> void:
	if _store == null:
		_store = FileSaveStore.new()
	load_local()


func configure_for_testing(store: Variant, save_path: String) -> void:
	_store = store
	_save_path = save_path
	_data = _default_data()
	diagnostics.clear()
	_pending_import.clear()


func load_local() -> Dictionary:
	diagnostics.clear()
	_data = _default_data()
	if _store == null:
		_store = FileSaveStore.new()
	if not _store.exists(_save_path):
		return {"ok": true, "status": "missing"}

	var read_result: Dictionary = _store.read_text(_save_path)
	if not read_result.ok:
		diagnostics.append("Could not read local save: %s" % read_result.error)
		return {"ok": false, "status": "read_error"}
	var validation: Dictionary = _validate_save_text(read_result.text)
	if validation.ok:
		_data = validation.data
		return {"ok": true, "status": "loaded"}
	if validation.unsupported:
		diagnostics.append("Local save has an unsupported version and was preserved: %s" % validation.error)
		return {"ok": false, "status": "unsupported"}

	var quarantine_result := _quarantine_invalid_save()
	if quarantine_result.ok:
		diagnostics.append("Invalid local save was quarantined to %s: %s" % [quarantine_result.path, validation.error])
	else:
		diagnostics.append("Invalid local save could not be quarantined: %s" % quarantine_result.error)
	return {"ok": false, "status": "invalid"}


func get_master_volume() -> float:
	return float(_data.settings.master_volume)


func set_master_volume(volume: float) -> Dictionary:
	if is_nan(volume) or is_inf(volume) or volume < 0.0 or volume > 1.0:
		return {"ok": false, "error": "Master volume must be within 0.0..1.0."}
	_data.settings.master_volume = volume
	return _persist_data(_data)


func get_high_score(song_id: String, difficulty: String) -> int:
	if not _data.scores.has(song_id):
		return 0
	return int(_data.scores[song_id].get(difficulty, 0))


func record_high_score(song_id: String, difficulty: String, score: int) -> Dictionary:
	if not _is_stable_id(song_id) or not _is_stable_id(difficulty):
		return {"ok": false, "new_record": false, "error": "Song and difficulty IDs must be stable lowercase kebab-case IDs."}
	if score < 0:
		return {"ok": false, "new_record": false, "error": "High score cannot be negative."}
	var previous: int = get_high_score(song_id, difficulty)
	if score <= previous:
		return {"ok": true, "new_record": false, "error": ""}
	if not _data.scores.has(song_id):
		_data.scores[song_id] = {}
	_data.scores[song_id][difficulty] = score
	var persisted: Dictionary = _persist_data(_data)
	return {"ok": persisted.ok, "new_record": persisted.ok, "error": persisted.error}


func persist() -> Dictionary:
	return _persist_data(_data)


func export_json(exported_at: String = "") -> Dictionary:
	var export_data: Dictionary = _copy_data(_data)
	export_data["exported_at"] = exported_at if not exported_at.is_empty() else _utc_timestamp()
	return {
		"filename": "baile-dos-crias-save-v1.json",
		"json": JSON.stringify(export_data, "\t"),
	}


func prepare_import(json_text: String) -> Dictionary:
	var validation: Dictionary = _validate_save_text(json_text)
	if not validation.ok:
		return {"ok": false, "token": "", "error": validation.error}
	_pending_import_counter += 1
	var token: String = "import-%d" % _pending_import_counter
	_pending_import = {"token": token, "data": validation.data}
	return {"ok": true, "token": token, "error": ""}


func confirm_import(token: String) -> Dictionary:
	if _pending_import.is_empty() or token != _pending_import.token:
		return {"ok": false, "error": "No matching validated import is pending."}
	var candidate: Dictionary = _pending_import.data
	var persisted: Dictionary = _persist_data(candidate)
	if not persisted.ok:
		return persisted
	_data = _copy_data(candidate)
	_pending_import.clear()
	return {"ok": true, "error": ""}


func cancel_import(token: String) -> bool:
	if _pending_import.is_empty() or token != _pending_import.token:
		return false
	_pending_import.clear()
	return true


func snapshot() -> Dictionary:
	return _copy_data(_data)


func _persist_data(data: Dictionary) -> Dictionary:
	if _store == null:
		_store = FileSaveStore.new()
	var result: Dictionary = _store.write_text(_save_path, JSON.stringify(data, "\t"))
	if not result.ok:
		diagnostics.append("Could not persist save: %s" % result.error)
	return result


func _validate_save_text(text: String) -> Dictionary:
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {"ok": false, "unsupported": false, "error": "Malformed JSON: %s" % json.get_error_message()}
	if not json.data is Dictionary:
		return {"ok": false, "unsupported": false, "error": "Save root must be an object."}
	var source: Dictionary = json.data
	if source.get("format", null) != SAVE_FORMAT:
		return {"ok": false, "unsupported": false, "error": "Unsupported save format."}
	var version_value: Variant = source.get("version", null)
	if not _is_integer_number(version_value):
		return {"ok": false, "unsupported": false, "error": "Save version must be an integer."}
	if int(version_value) != SAVE_VERSION:
		return {"ok": false, "unsupported": true, "error": "Unsupported save version %d." % int(version_value)}
	if source.has("exported_at") and not source.exported_at is String:
		return {"ok": false, "unsupported": false, "error": "exported_at must be a string when present."}
	if not source.get("settings", null) is Dictionary:
		return {"ok": false, "unsupported": false, "error": "settings must be an object."}
	var master_volume_value: Variant = source.settings.get("master_volume", null)
	if not master_volume_value is float and not master_volume_value is int:
		return {"ok": false, "unsupported": false, "error": "settings.master_volume must be numeric."}
	var volume: float = float(master_volume_value)
	if is_nan(volume) or is_inf(volume) or volume < 0.0 or volume > 1.0:
		return {"ok": false, "unsupported": false, "error": "settings.master_volume must be within 0.0..1.0."}
	if not source.get("scores", null) is Dictionary:
		return {"ok": false, "unsupported": false, "error": "scores must be an object."}

	var scores: Dictionary = {}
	for song_id_variant in source.scores:
		var song_id: String = String(song_id_variant)
		if not _is_stable_id(song_id):
			return {"ok": false, "unsupported": false, "error": "scores has an invalid song ID."}
		var difficulty_scores: Variant = source.scores[song_id_variant]
		if not difficulty_scores is Dictionary:
			return {"ok": false, "unsupported": false, "error": "scores.%s must be an object." % song_id}
		scores[song_id] = {}
		for difficulty_variant in difficulty_scores:
			var difficulty: String = String(difficulty_variant)
			var score: Variant = difficulty_scores[difficulty_variant]
			if not _is_stable_id(difficulty) or not _is_integer_number(score) or int(score) < 0:
				return {"ok": false, "unsupported": false, "error": "scores.%s contains an invalid difficulty or score." % song_id}
			scores[song_id][difficulty] = int(score)

	return {"ok": true, "unsupported": false, "error": "", "data": {
		"format": SAVE_FORMAT,
		"version": SAVE_VERSION,
		"settings": {"master_volume": volume},
		"scores": scores,
	}}


func _quarantine_invalid_save() -> Dictionary:
	var stamp: String = _utc_timestamp().replace("-", "").replace(":", "").replace("T", "-").replace("Z", "")
	var candidate: String = "%s.invalid-%s.json" % [_save_path.trim_suffix(".json"), stamp]
	var suffix: int = 1
	while _store.exists(candidate):
		candidate = "%s.invalid-%s-%d.json" % [_save_path.trim_suffix(".json"), stamp, suffix]
		suffix += 1
	var result: Dictionary = _store.rename(_save_path, candidate)
	if result.ok:
		result["path"] = candidate
	return result


func _default_data() -> Dictionary:
	return {
		"format": SAVE_FORMAT,
		"version": SAVE_VERSION,
		"settings": {"master_volume": 1.0},
		"scores": {},
	}


func _copy_data(data: Dictionary) -> Dictionary:
	return data.duplicate(true)


func _utc_timestamp() -> String:
	return Time.get_datetime_string_from_system(true, false) + "Z"


func _is_stable_id(value: String) -> bool:
	var regex: RegEx = RegEx.new()
	regex.compile("^[a-z0-9]+(?:-[a-z0-9]+)*$")
	return regex.search(value) != null


func _is_integer_number(value: Variant) -> bool:
	return value is int or (value is float and floor(value) == value)
