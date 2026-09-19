class_name InputRouter
extends RefCounted

signal pad_pressed(pad: int)
signal pad_released(pad: int)

const KEY_TO_PAD := {
	KEY_Q: 7, KEY_W: 8, KEY_E: 9,
	KEY_A: 4, KEY_S: 5, KEY_D: 6,
	KEY_Z: 1, KEY_X: 2, KEY_C: 3,
	KEY_KP_7: 7, KEY_KP_8: 8, KEY_KP_9: 9,
	KEY_KP_4: 4, KEY_KP_5: 5, KEY_KP_6: 6,
	KEY_KP_1: 1, KEY_KP_2: 2, KEY_KP_3: 3,
}

var _sources_by_pad := {}
var _pad_by_source := {}


func handle_key_event(event: InputEventKey) -> bool:
	if event.echo:
		return false
	var code := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not KEY_TO_PAD.has(code):
		return false
	var source := "key:%d" % code
	if event.pressed:
		return press_source(source, int(KEY_TO_PAD[code]))
	return release_source(source)


func press_source(source: String, pad: int) -> bool:
	if pad < 1 or pad > 9 or _pad_by_source.has(source):
		return false
	if not _sources_by_pad.has(pad):
		_sources_by_pad[pad] = {}
	var source_set: Dictionary = _sources_by_pad[pad]
	var was_inactive := source_set.is_empty()
	source_set[source] = true
	_pad_by_source[source] = pad
	if was_inactive:
		pad_pressed.emit(pad)
	return true


func release_source(source: String) -> bool:
	if not _pad_by_source.has(source):
		return false
	var pad := int(_pad_by_source[source])
	_pad_by_source.erase(source)
	var source_set: Dictionary = _sources_by_pad[pad]
	source_set.erase(source)
	if source_set.is_empty():
		pad_released.emit(pad)
	return true


func begin_mouse(button_index: int, pad: int) -> bool:
	return press_source("mouse:%d" % button_index, pad)


func end_mouse(button_index: int) -> bool:
	return release_source("mouse:%d" % button_index)


func begin_touch(touch_index: int, pad: int) -> bool:
	return press_source("touch:%d" % touch_index, pad)


func end_touch(touch_index: int) -> bool:
	return release_source("touch:%d" % touch_index)


func get_touch_pad(touch_index: int) -> int:
	return int(_pad_by_source.get("touch:%d" % touch_index, 0))


func is_pad_held(pad: int) -> bool:
	return _sources_by_pad.has(pad) and not Dictionary(_sources_by_pad[pad]).is_empty()


func clear_all_sources() -> void:
	var active_pads: Array[int] = []
	for pad_variant in _sources_by_pad:
		var pad := int(pad_variant)
		if not Dictionary(_sources_by_pad[pad]).is_empty():
			active_pads.append(pad)
	active_pads.sort()
	_sources_by_pad.clear()
	_pad_by_source.clear()
	for pad in active_pads:
		pad_released.emit(pad)
