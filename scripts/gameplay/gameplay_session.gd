class_name GameplaySession
extends RefCounted

const NoteControllerScript = preload("res://scripts/gameplay/note_controller.gd")
const ScoreTrackerScript = preload("res://scripts/gameplay/score_tracker.gd")

const IDLE := "idle"
const RUNNING := "running"
const SUCCESS := "success"
const FAILURE := "failure"

var status := IDLE
var last_error := ""
var note_controller = NoteControllerScript.new()
var score_tracker = ScoreTrackerScript.new()
var _chart := {}


func start(chart: Dictionary) -> void:
	_chart = chart.duplicate(true)
	note_controller.load_chart(_chart)
	score_tracker.reset()
	last_error = ""
	status = RUNNING


func retry() -> void:
	if _chart.is_empty():
		last_error = "Cannot retry before a chart is loaded."
		return
	start(_chart)


func reset() -> void:
	_chart.clear()
	note_controller.reset()
	score_tracker.reset()
	last_error = ""
	status = IDLE


func advance_to(time_ms: int) -> Array[Dictionary]:
	if status != RUNNING:
		return []
	return _apply(note_controller.advance_to(time_ms))


func press_pad(pad: int, time_ms: int) -> Array[Dictionary]:
	if status != RUNNING:
		return []
	return _apply(note_controller.press_pad(pad, time_ms))


func release_pad(pad: int, time_ms: int) -> Array[Dictionary]:
	if status != RUNNING:
		return []
	return _apply(note_controller.release_pad(pad, time_ms))


func finish_song(time_ms: int) -> Dictionary:
	if status != RUNNING:
		return result()
	_apply(note_controller.finalize_at(time_ms))
	if status == RUNNING:
		status = SUCCESS
	return result()


func result() -> Dictionary:
	var value := score_tracker.snapshot()
	value["status"] = status
	return value


func _apply(judgments: Array[Dictionary]) -> Array[Dictionary]:
	var applied: Array[Dictionary] = []
	for judgment_event in judgments:
		if status != RUNNING:
			break
		var score_event: Dictionary = score_tracker.apply_judgment(judgment_event.judgment)
		var combined := judgment_event.duplicate(true)
		combined["score"] = score_event
		applied.append(combined)
		if score_tracker.failed:
			status = FAILURE
	return applied
