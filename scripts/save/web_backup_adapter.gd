class_name WebBackupAdapter
extends RefCounted

signal import_text_received(text: String)
signal import_request_failed(message: String)

var _import_callback: Variant = null


func is_supported() -> bool:
	return OS.has_feature("web")


func download_json(filename: String, text: String) -> Dictionary:
	if not is_supported():
		return {"ok": false, "error": "Browser backup download is only available in Web builds."}
	var script := """
const blob = new Blob([%s], {type: 'application/json'});
const anchor = document.createElement('a');
anchor.href = URL.createObjectURL(blob);
anchor.download = %s;
anchor.click();
URL.revokeObjectURL(anchor.href);
""" % [JSON.stringify(text), JSON.stringify(filename)]
	JavaScriptBridge.eval(script, true)
	return {"ok": true, "error": ""}


func request_import_file() -> Dictionary:
	if not is_supported():
		return {"ok": false, "error": "Browser backup import is only available in Web builds."}
	_import_callback = JavaScriptBridge.create_callback(_on_browser_import)
	var script := """
const input = document.createElement('input');
input.type = 'file';
input.accept = 'application/json,.json';
input.onchange = () => {
  const file = input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => %s(reader.result);
  reader.onerror = () => %s('Could not read the selected backup file.');
  reader.readAsText(file);
};
input.click();
""" % [_import_callback, _import_callback]
	JavaScriptBridge.eval(script, true)
	return {"ok": true, "error": ""}


func _on_browser_import(arguments: Array) -> void:
	if arguments.is_empty() or not arguments[0] is String:
		import_request_failed.emit("Browser backup import returned no text.")
		return
	var text := String(arguments[0])
	if text.begins_with("Could not read the selected backup file."):
		import_request_failed.emit(text)
		return
	import_text_received.emit(text)
