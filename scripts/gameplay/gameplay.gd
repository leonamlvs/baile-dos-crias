class_name Gameplay
extends Control

signal judgments_applied(events: Array[Dictionary])
signal session_completed(result: Dictionary)

const GameplaySessionScript = preload("res://scripts/gameplay/gameplay_session.gd")

var session = GameplaySessionScript.new()
var _chart := {}
var _time_source := Callable()
var _last_time_ms := 0
var _forward_pad_signals := true
var _completion_emitted := false

@onready var pad_grid = $PadGrid


func _ready() -> void:
	pad_grid.pad_pressed.connect(_on_pad_pressed)
	pad_grid.pad_released.connect(_on_pad_released)
	set_process(false)


func begin_session(chart: Dictionary, time_source: Callable = Callable()) -> void:
	_chart = chart.duplicate(true)
	_time_source = time_source
	_last_time_ms = 0
	_completion_emitted = false
	_clear_input_without_forwarding()
	session.start(_chart)
	pad_grid.configure_notes(_chart, session.note_controller)
	set_process(_time_source.is_valid())


func retry_session() -> void:
	if _chart.is_empty():
		return
	_clear_input_without_forwarding()
	_last_time_ms = 0
	_completion_emitted = false
	session.retry()
	pad_grid.configure_notes(_chart, session.note_controller)
	set_process(_time_source.is_valid())


func stop_session() -> void:
	_clear_input_without_forwarding()
	_chart.clear()
	_time_source = Callable()
	_last_time_ms = 0
	_completion_emitted = false
	session.reset()
	pad_grid.clear_notes()
	set_process(false)


func advance_to(time_ms: int) -> Array[Dictionary]:
	_last_time_ms = maxi(_last_time_ms, time_ms)
	var events: Array[Dictionary] = session.advance_to(time_ms)
	pad_grid.set_song_time_ms(time_ms)
	_notify_events(events)
	_notify_terminal_status()
	return events


func press_pad_at(pad: int, time_ms: int) -> Array[Dictionary]:
	_last_time_ms = maxi(_last_time_ms, time_ms)
	var events: Array[Dictionary] = session.press_pad(pad, time_ms)
	pad_grid.set_song_time_ms(time_ms)
	_notify_events(events)
	_notify_terminal_status()
	return events


func release_pad_at(pad: int, time_ms: int) -> Array[Dictionary]:
	_last_time_ms = maxi(_last_time_ms, time_ms)
	var events: Array[Dictionary] = session.release_pad(pad, time_ms)
	pad_grid.set_song_time_ms(time_ms)
	_notify_events(events)
	_notify_terminal_status()
	return events


func finish_song(time_ms: int) -> Dictionary:
	_last_time_ms = maxi(_last_time_ms, time_ms)
	var result: Dictionary = session.finish_song(time_ms)
	pad_grid.set_song_time_ms(time_ms)
	_notify_terminal_status()
	return result


func _process(_delta: float) -> void:
	if session.status != GameplaySessionScript.RUNNING or not _time_source.is_valid():
		return
	advance_to(int(_time_source.call()))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and pad_grid.handle_key_event(event):
		get_viewport().set_input_as_handled()


func _current_input_time_ms() -> int:
	if _time_source.is_valid():
		return int(_time_source.call())
	return _last_time_ms


func _on_pad_pressed(pad: int) -> void:
	if _forward_pad_signals:
		press_pad_at(pad, _current_input_time_ms())


func _on_pad_released(pad: int) -> void:
	if _forward_pad_signals:
		release_pad_at(pad, _current_input_time_ms())


func _clear_input_without_forwarding() -> void:
	_forward_pad_signals = false
	pad_grid.clear_all_sources()
	_forward_pad_signals = true


func _notify_events(events: Array[Dictionary]) -> void:
	if not events.is_empty():
		judgments_applied.emit(events)


func _notify_terminal_status() -> void:
	if _completion_emitted:
		return
	if session.status in [GameplaySessionScript.SUCCESS, GameplaySessionScript.FAILURE]:
		_completion_emitted = true
		set_process(false)
		session_completed.emit(session.result())
