class_name FileSaveStore
extends RefCounted


func exists(path: String) -> bool:
	return FileAccess.file_exists(path)


func read_text(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "text": "", "error": "Could not open save for reading."}
	var text := file.get_as_text()
	file.close()
	return {"ok": true, "text": text, "error": ""}


func write_text(path: String, text: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open save for writing."}
	file.store_string(text)
	file.close()
	return {"ok": true, "error": ""}


func rename(path: String, destination: String) -> Dictionary:
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(destination))
	if result != OK:
		return {"ok": false, "error": "Could not quarantine invalid save (error %d)." % result}
	return {"ok": true, "error": ""}
