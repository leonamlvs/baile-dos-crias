class_name MemorySaveStore
extends RefCounted

var files := {}
var renamed_paths: Array[Dictionary] = []


func exists(path: String) -> bool:
	return files.has(path)


func read_text(path: String) -> Dictionary:
	if not files.has(path):
		return {"ok": false, "text": "", "error": "File does not exist."}
	return {"ok": true, "text": String(files[path]), "error": ""}


func write_text(path: String, text: String) -> Dictionary:
	files[path] = text
	return {"ok": true, "error": ""}


func rename(path: String, destination: String) -> Dictionary:
	if not files.has(path):
		return {"ok": false, "error": "File does not exist."}
	if files.has(destination):
		return {"ok": false, "error": "Destination already exists."}
	files[destination] = files[path]
	files.erase(path)
	renamed_paths.append({"from": path, "to": destination})
	return {"ok": true, "error": ""}
