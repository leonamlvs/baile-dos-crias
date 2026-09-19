class_name PadGrid
extends Control

signal pad_pressed(pad: int)
signal pad_released(pad: int)

const InputRouterScript = preload("res://scripts/input/input_router.gd")
const NoteVisualStateScript = preload("res://scripts/gameplay/note_visual_state.gd")

@export_range(0.0, 32.0, 1.0) var gutter := 8.0
@export_range(1, 5000, 1) var approach_ms := 1000
@export var pad_color := Color("284466")
@export var pad_outline_color := Color("6fa8dc")
@export var tap_color := Color.WHITE
@export var hold_color := Color("74c7ec")

var _router = InputRouterScript.new()
var _chart := {}
var _note_controller: Variant = null
var _song_time_ms := 0


func _ready() -> void:
	_router.pad_pressed.connect(_on_router_pad_pressed)
	_router.pad_released.connect(_on_router_pad_released)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func configure_notes(chart: Dictionary, note_controller: Variant) -> void:
	_chart = chart.duplicate(true)
	_note_controller = note_controller
	_song_time_ms = 0
	queue_redraw()


func clear_notes() -> void:
	_chart.clear()
	_note_controller = null
	_song_time_ms = 0
	queue_redraw()


func set_song_time_ms(value: int) -> void:
	_song_time_ms = maxi(0, value)
	queue_redraw()


func handle_key_event(event: InputEventKey) -> bool:
	return _router.handle_key_event(event)


func clear_all_sources() -> void:
	_router.clear_all_sources()


func pad_at_position(local_position: Vector2) -> int:
	if local_position.x < 0.0 or local_position.y < 0.0:
		return 0
	if local_position.x >= size.x or local_position.y >= size.y:
		return 0
	for row in range(3):
		for column in range(3):
			if _pad_rect(row, column).has_point(local_position):
				return (2 - row) * 3 + column + 1
	return 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var pad := pad_at_position(event.position)
			if pad != 0:
				_router.begin_mouse(MOUSE_BUTTON_LEFT, pad)
		else:
			_router.end_mouse(MOUSE_BUTTON_LEFT)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			var pad := pad_at_position(event.position)
			if pad != 0:
				_router.begin_touch(event.index, pad)
		else:
			_router.end_touch(event.index)
		accept_event()
	# ScreenDrag is intentionally ignored: a touch stays on its initial pad.


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if _router != null:
			_router.clear_all_sources()


func _draw() -> void:
	for row in range(3):
		for column in range(3):
			var rect := _pad_rect(row, column)
			var pad := (2 - row) * 3 + column + 1
			var fill := pad_color.lightened(0.2) if _router.is_pad_held(pad) else pad_color
			draw_rect(rect, fill, true)
			draw_rect(rect, pad_outline_color, false, 2.0)
	_draw_notes()


func _draw_notes() -> void:
	if _chart.is_empty() or _note_controller == null:
		return
	for note_value in _chart.get("notes", []):
		var note: Dictionary = note_value
		var hit_time_ms := int(note.time_ms)
		if _song_time_ms < hit_time_ms - approach_ms:
			continue
		var state: Dictionary = _note_controller.get_note_state(String(note.id))
		if state.is_empty():
			continue
		var pad_rect := rect_for_pad(int(note.pad))
		if note.type == "tap":
			if state.initial_judged:
				continue
			_draw_tap_note(pad_rect, hit_time_ms)
		elif not state.ended:
			_draw_hold_note(pad_rect, hit_time_ms, int(note.end_ms))


func _draw_tap_note(pad_rect: Rect2, hit_time_ms: int) -> void:
	var progress := NoteVisualStateScript.approach_progress(
		_song_time_ms,
		hit_time_ms,
		approach_ms,
	)
	var note_rect := _scaled_from_center(pad_rect, progress)
	draw_rect(note_rect, tap_color, false, 4.0)


func _draw_hold_note(pad_rect: Rect2, hit_time_ms: int, end_time_ms: int) -> void:
	var approach := NoteVisualStateScript.approach_progress(
		_song_time_ms,
		hit_time_ms,
		approach_ms,
	)
	var note_rect := _scaled_from_center(pad_rect, approach)
	var progress := NoteVisualStateScript.hold_progress(
		_song_time_ms,
		hit_time_ms,
		end_time_ms,
	)
	var base_fill := hold_color
	base_fill.a = lerpf(0.12, 0.28, progress)
	draw_rect(note_rect, base_fill, true)
	if progress > 0.0:
		var progress_rect := Rect2(
			note_rect.position + Vector2(0.0, note_rect.size.y * (1.0 - progress)),
			Vector2(note_rect.size.x, note_rect.size.y * progress),
		)
		var progress_fill := hold_color
		progress_fill.a = 0.5
		draw_rect(progress_rect, progress_fill, true)


func rect_for_pad(pad: int) -> Rect2:
	if pad < 1 or pad > 9:
		return Rect2()
	var row := 2 - ((pad - 1) / 3)
	var column := (pad - 1) % 3
	return _pad_rect(row, column)


func _pad_rect(row: int, column: int) -> Rect2:
	var cell_size := Vector2(
		maxf(0.0, (size.x - gutter * 2.0) / 3.0),
		maxf(0.0, (size.y - gutter * 2.0) / 3.0),
	)
	return Rect2(
		Vector2(column * (cell_size.x + gutter), row * (cell_size.y + gutter)),
		cell_size,
	)


func _scaled_from_center(rect: Rect2, factor: float) -> Rect2:
	var scaled_size := rect.size * clampf(factor, 0.0, 1.0)
	return Rect2(rect.get_center() - scaled_size * 0.5, scaled_size)


func _on_router_pad_pressed(pad: int) -> void:
	queue_redraw()
	pad_pressed.emit(pad)


func _on_router_pad_released(pad: int) -> void:
	queue_redraw()
	pad_released.emit(pad)
