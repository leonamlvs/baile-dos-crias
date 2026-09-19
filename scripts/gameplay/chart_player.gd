class_name ChartPlayer
extends RefCounted

var last_error := ""
var _events: Array[Dictionary] = []
var _cursor := 0
var _last_time_ms := 0


func load_chart(chart: Dictionary) -> void:
	_events.clear()
	_cursor = 0
	_last_time_ms = 0
	last_error = ""
	var sequence := 0
	for note in chart.get("notes", []):
		_events.append({
			"time_ms": int(note.time_ms),
			"kind": "note",
			"note": note.duplicate(true),
			"sequence": sequence,
		})
		sequence += 1
		if note.type == "hold":
			for tick_ms in note.ticks_ms:
				_events.append({
					"time_ms": int(tick_ms),
					"kind": "hold_tick",
					"note_id": note.id,
					"pad": int(note.pad),
					"sequence": sequence,
				})
				sequence += 1
			_events.append({
				"time_ms": int(note.end_ms),
				"kind": "hold_end",
				"note_id": note.id,
				"pad": int(note.pad),
				"sequence": sequence,
			})
			sequence += 1
	_events.sort_custom(_event_precedes)


func advance_to(time_ms: int) -> Array[Dictionary]:
	if time_ms < _last_time_ms:
		last_error = "ChartPlayer cannot advance backwards; call reset for retry."
		return []
	last_error = ""
	_last_time_ms = time_ms
	var due: Array[Dictionary] = []
	while _cursor < _events.size() and int(_events[_cursor].time_ms) <= time_ms:
		var event: Dictionary = _events[_cursor].duplicate(true)
		event.erase("sequence")
		due.append(event)
		_cursor += 1
	return due


func reset() -> void:
	_cursor = 0
	_last_time_ms = 0
	last_error = ""


func is_exhausted() -> bool:
	return _cursor >= _events.size()


func pending_event_count() -> int:
	return _events.size() - _cursor


func _event_precedes(left: Dictionary, right: Dictionary) -> bool:
	if left.time_ms == right.time_ms:
		return int(left.sequence) < int(right.sequence)
	return int(left.time_ms) < int(right.time_ms)
