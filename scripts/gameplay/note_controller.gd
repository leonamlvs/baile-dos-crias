class_name NoteController
extends RefCounted

const JudgmentRulesScript = preload("res://scripts/gameplay/judgment_rules.gd")

var last_error := ""
var _notes: Array[Dictionary] = []
var _notes_by_id := {}
var _scheduled: Array[Dictionary] = []
var _schedule_cursor := 0
var _held_pads := {}
var _last_time_ms := -1


func load_chart(chart: Dictionary) -> void:
	reset()
	var sequence := 0
	for note_value in chart.get("notes", []):
		var note: Dictionary = note_value.duplicate(true)
		var state := {
			"note": note,
			"sequence": sequence,
			"initial_judged": false,
			"initial_judgment": "",
			"ended": false,
			"ticks_processed": 0,
		}
		_notes.append(state)
		_notes_by_id[note.id] = state
		if note.type == "hold":
			_add_scheduled(int(note.time_ms), "hold_hit", note.id, sequence)
			for tick_index in range(note.ticks_ms.size()):
				_add_scheduled(
					int(note.ticks_ms[tick_index]),
					"hold_tick",
					note.id,
					sequence,
					tick_index,
				)
			_add_scheduled(int(note.end_ms), "hold_end", note.id, sequence)
		_add_scheduled(
			int(note.time_ms) + JudgmentRulesScript.MAX_HIT_WINDOW_MS + 1,
			"initial_expire",
			note.id,
			sequence,
		)
		sequence += 1
	_scheduled.sort_custom(_scheduled_precedes)


func reset() -> void:
	last_error = ""
	_notes.clear()
	_notes_by_id.clear()
	_scheduled.clear()
	_schedule_cursor = 0
	_held_pads.clear()
	_last_time_ms = -1


func advance_to(time_ms: int) -> Array[Dictionary]:
	if not _can_advance(time_ms):
		return []
	return _process_through(time_ms, true)


func press_pad(pad: int, time_ms: int) -> Array[Dictionary]:
	if not _validate_pad_and_time(pad, time_ms):
		return []
	var judgments := _process_through(time_ms, false)
	if _held_pads.has(pad):
		judgments.append_array(_process_through(time_ms, true))
		return judgments

	_held_pads[pad] = true
	var candidate := _find_press_candidate(pad, time_ms)
	if not candidate.is_empty():
		var note: Dictionary = candidate.note
		judgments.append(_judge_initial(candidate, JudgmentRulesScript.classify(time_ms - int(note.time_ms)), time_ms))
	judgments.append_array(_process_through(time_ms, true))
	return judgments


func release_pad(pad: int, time_ms: int) -> Array[Dictionary]:
	if not _validate_pad_and_time(pad, time_ms):
		return []
	var judgments := _process_through(time_ms, false)
	_held_pads.erase(pad)
	judgments.append_array(_process_through(time_ms, true))
	return judgments


func finalize_at(time_ms: int) -> Array[Dictionary]:
	var judgments := advance_to(time_ms)
	if not last_error.is_empty():
		return judgments
	for state in _notes:
		var note: Dictionary = state.note
		if not state.initial_judged and int(note.time_ms) <= time_ms:
			judgments.append(_judge_initial(state, JudgmentRulesScript.MISS, time_ms))
	return judgments


func is_pad_held(pad: int) -> bool:
	return _held_pads.has(pad)


func get_note_state(note_id: String) -> Dictionary:
	if not _notes_by_id.has(note_id):
		return {}
	var state: Dictionary = _notes_by_id[note_id]
	return {
		"initial_judged": state.initial_judged,
		"initial_judgment": state.initial_judgment,
		"ended": state.ended,
		"ticks_processed": state.ticks_processed,
	}


func all_notes_complete() -> bool:
	for state in _notes:
		if not state.initial_judged:
			return false
		if state.note.type == "hold" and not state.ended:
			return false
	return true


func _find_press_candidate(pad: int, time_ms: int) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := JudgmentRulesScript.MAX_HIT_WINDOW_MS + 1
	for state in _notes:
		if state.initial_judged:
			continue
		var note: Dictionary = state.note
		if int(note.pad) != pad:
			continue
		var distance := absi(time_ms - int(note.time_ms))
		if distance > JudgmentRulesScript.MAX_HIT_WINDOW_MS:
			continue
		if (
			distance < best_distance
			or (
				distance == best_distance
				and (best.is_empty() or int(state.sequence) < int(best.sequence))
			)
		):
			best = state
			best_distance = distance
	return best


func _judge_initial(state: Dictionary, judgment: String, event_time_ms: int) -> Dictionary:
	state.initial_judged = true
	state.initial_judgment = judgment
	var note: Dictionary = state.note
	return {
		"note_id": note.id,
		"pad": int(note.pad),
		"source": "initial",
		"judgment": judgment,
		"time_ms": event_time_ms,
		"delta_ms": event_time_ms - int(note.time_ms),
	}


func _process_through(time_ms: int, inclusive: bool) -> Array[Dictionary]:
	var judgments: Array[Dictionary] = []
	while _schedule_cursor < _scheduled.size():
		var event: Dictionary = _scheduled[_schedule_cursor]
		var event_time := int(event.time_ms)
		if event_time > time_ms or (not inclusive and event_time == time_ms):
			break
		_schedule_cursor += 1
		var state: Dictionary = _notes_by_id[event.note_id]
		var note: Dictionary = state.note
		match event.kind:
			"hold_hit":
				if not state.initial_judged and _held_pads.has(int(note.pad)):
					judgments.append(_judge_initial(state, JudgmentRulesScript.PERFECT, event_time))
			"hold_tick":
				state.ticks_processed = int(state.ticks_processed) + 1
				judgments.append({
					"note_id": note.id,
					"pad": int(note.pad),
					"source": "hold_tick",
					"tick_index": int(event.tick_index),
					"judgment": JudgmentRulesScript.PERFECT if _held_pads.has(int(note.pad)) else JudgmentRulesScript.MISS,
					"time_ms": event_time,
					"delta_ms": 0,
				})
			"initial_expire":
				if not state.initial_judged:
					judgments.append(_judge_initial(state, JudgmentRulesScript.MISS, event_time))
			"hold_end":
				state.ended = true
	_last_time_ms = time_ms
	return judgments


func _add_scheduled(
	time_ms: int,
	kind: String,
	note_id: String,
	note_sequence: int,
	tick_index: int = -1,
) -> void:
	_scheduled.append({
		"time_ms": time_ms,
		"kind": kind,
		"note_id": note_id,
		"note_sequence": note_sequence,
		"tick_index": tick_index,
		"priority": _event_priority(kind),
	})


func _scheduled_precedes(left: Dictionary, right: Dictionary) -> bool:
	if left.time_ms != right.time_ms:
		return int(left.time_ms) < int(right.time_ms)
	if left.priority != right.priority:
		return int(left.priority) < int(right.priority)
	return int(left.note_sequence) < int(right.note_sequence)


func _event_priority(kind: String) -> int:
	match kind:
		"hold_hit":
			return 0
		"hold_tick":
			return 1
		"initial_expire":
			return 2
		_:
			return 3


func _can_advance(time_ms: int) -> bool:
	if time_ms < _last_time_ms:
		last_error = "NoteController cannot advance backwards; reset for a new session."
		return false
	last_error = ""
	return true


func _validate_pad_and_time(pad: int, time_ms: int) -> bool:
	if pad < 1 or pad > 9:
		last_error = "Pad must be from 1 through 9."
		return false
	return _can_advance(time_ms)
