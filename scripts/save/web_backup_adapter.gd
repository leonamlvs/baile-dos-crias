class_name WebBackupAdapter
extends RefCounted

signal import_text_received(text: String)
signal import_request_failed(message: String)

var _import_callback: Variant = null
var _window: Variant = null

const IMPORT_CALLBACK_NAME := "__baileDosCriasImportBackup"


func is_supported() -> bool:
	return OS.has_feature("web")


func download_json(filename: String, text: String) -> Dictionary:
	if not is_supported():
		return {"ok": false, "error": "Browser backup download is only available in Web builds."}
	var script := """
const blob = new Blob([%s], {type: 'application/json'});
const anchor = document.createElement('a');
const url = URL.createObjectURL(blob);
anchor.href = url;
anchor.download = %s;
document.body.appendChild(anchor);
anchor.click();
anchor.remove();
setTimeout(() => URL.revokeObjectURL(url), 0);
""" % [JSON.stringify(text), JSON.stringify(filename)]
	JavaScriptBridge.eval(script, true)
	return {"ok": true, "error": ""}


func request_import_file() -> Dictionary:
	if not is_supported():
		return {"ok": false, "error": "Browser backup import is only available in Web builds."}
	_import_callback = JavaScriptBridge.create_callback(_on_browser_import)
	_window = JavaScriptBridge.get_interface("window")
	if _window == null:
		return {"ok": false, "error": "Browser window API is unavailable."}
	_window.set(IMPORT_CALLBACK_NAME, _import_callback)
	var script := """
const input = document.createElement('input');
input.type = 'file';
input.accept = 'application/json,.json';
input.onchange = () => {
  const file = input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => window.%s('ok', reader.result);
  reader.onerror = () => window.%s('error', 'Could not read the selected backup file.');
  reader.readAsText(file);
};
input.click();
""" % [IMPORT_CALLBACK_NAME, IMPORT_CALLBACK_NAME]
	JavaScriptBridge.eval(script, true)
	return {"ok": true, "error": ""}


func _on_browser_import(arguments: Array) -> void:
	if arguments.size() < 2 or not arguments[0] is String or not arguments[1] is String:
		import_request_failed.emit("Browser backup import returned no text.")
		return
	if String(arguments[0]) == "error":
		import_request_failed.emit(String(arguments[1]))
		return
	import_text_received.emit(String(arguments[1]))
