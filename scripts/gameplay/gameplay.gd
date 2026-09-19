class_name Gameplay
extends Control

signal judgments_applied(events: Array[Dictionary])
signal session_completed(result: Dictionary)

const GameplaySessionScript = preload("res://scripts/gameplay/gameplay_session.gd")
const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const RuntimeChartParserScript = preload("res://scripts/data/runtime_chart_parser.gd")
const UiHelpersScript = preload("res://scripts/ui/ui_helpers.gd")

var session = GameplaySessionScript.new()
var _chart := {}
var _time_source := Callable()
var _last_time_ms := 0
var _forward_pad_signals := true
var _completion_emitted := false
var _countdown_active := false
var _countdown_started_at_ms := 0
var _countdown_mode := ""
var _pending_chart := {}
var _pending_stream: AudioStream
var _finalized_result := false
var _score_label: Label
var _countdown_label: Label
var _pause_overlay: Control
var _error_label: Label

@onready var pad_grid = $PadGrid


func _ready() -> void:
	pad_grid.pad_pressed.connect(_on_pad_pressed)
	pad_grid.pad_released.connect(_on_pad_released)
	session_completed.connect(_on_session_completed)
	_build_product_ui()
	set_process(false)
	call_deferred("_begin_selected_song")


func begin_session(chart: Dictionary, time_source: Callable = Callable()) -> void:
	_chart = chart.duplicate(true)
	_time_source = time_source
	_last_time_ms = 0
	_completion_emitted = false
	_finalized_result = false
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
	_finalized_result = false
	session.retry()
	pad_grid.configure_notes(_chart, session.note_controller)
	set_process(_time_source.is_valid())


func stop_session() -> void:
	_clear_input_without_forwarding()
	_chart.clear()
	_time_source = Callable()
	_last_time_ms = 0
	_completion_emitted = false
	_countdown_active = false
	_finalized_result = false
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
	if _countdown_active:
		_update_countdown()
		return
	if session.status != GameplaySessionScript.RUNNING or not _time_source.is_valid():
		return
	advance_to(int(_time_source.call()))
	if AudioManager.is_gameplay_finished() and session.status == GameplaySessionScript.RUNNING:
		finish_song(AudioManager.get_song_time_ms())


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
		if is_instance_valid(_score_label):
			_score_label.text = "SCORE %d\nCOMBO %d ×%d" % [
				session.score_tracker.score,
				session.score_tracker.combo,
				session.score_tracker.multiplier,
			]
		judgments_applied.emit(events)


func _notify_terminal_status() -> void:
	if _completion_emitted:
		return
	if session.status in [GameplaySessionScript.SUCCESS, GameplaySessionScript.FAILURE]:
		_completion_emitted = true
		set_process(false)
		session_completed.emit(session.result())


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_clear_input_without_forwarding()
		if session.status == GameplaySessionScript.RUNNING and not _countdown_active:
			pause_session()


func _begin_selected_song() -> void:
	if GameState.selected_song_id.is_empty() or GameState.selected_difficulty.is_empty():
		_show_error("Selecione uma música e dificuldade para jogar.")
		return
	var catalog = ContentCatalogScript.new()
	catalog.load_from_root()
	var lookup: Dictionary = catalog.get_item(ContentCatalogScript.CATEGORY_SONG, GameState.selected_song_id)
	if not lookup.ok:
		_show_error(lookup.error)
		return
	var song: Dictionary = lookup.item
	if not song.difficulties.has(GameState.selected_difficulty):
		_show_error("A dificuldade selecionada não está disponível.")
		return
	var chart_path := String(song.content_path).path_join("charts").path_join("%s.json" % GameState.selected_difficulty)
	var parsed: Dictionary = RuntimeChartParserScript.new().parse_file(chart_path, GameState.selected_song_id, GameState.selected_difficulty)
	if not parsed.ok:
		_show_error(parsed.error)
		return
	var stream := load(String(song.content_path).path_join(String(song.audio))) as AudioStream
	if stream == null:
		_show_error("Não foi possível carregar o áudio selecionado.")
		return
	_begin_countdown(parsed.chart, stream, "start")


func pause_session() -> void:
	if session.status != GameplaySessionScript.RUNNING or _countdown_active:
		return
	AudioManager.pause_gameplay()
	set_process(false)
	_pause_overlay.visible = true


func continue_session() -> void:
	if not _pause_overlay.visible:
		return
	_pause_overlay.visible = false
	_begin_countdown({}, null, "resume")


func retry_product_session() -> void:
	_pause_overlay.visible = false
	_begin_countdown({}, null, "retry")


func exit_to_song_select() -> void:
	AudioManager.stop_gameplay()
	stop_session()
	get_node("/root/ScreenRouter").go_to_song_select()


func _begin_countdown(chart: Dictionary, stream: AudioStream, mode: String) -> void:
	if mode == "start":
		_pending_chart = chart.duplicate(true)
		_pending_stream = stream
	elif _pending_chart.is_empty() or _pending_stream == null:
		_show_error("A sessão não possui música válida para reiniciar.")
		return
	_countdown_mode = mode
	_countdown_started_at_ms = Time.get_ticks_msec()
	_countdown_active = true
	_countdown_label.visible = true
	set_process(true)


func _update_countdown() -> void:
	var elapsed_ms := Time.get_ticks_msec() - _countdown_started_at_ms
	var step := elapsed_ms / 1000
	_countdown_label.text = ["3", "2", "1", "VAI!"][mini(step, 3)]
	if elapsed_ms < 4000:
		return
	_countdown_active = false
	_countdown_label.visible = false
	match _countdown_mode:
		"start":
			var started: Dictionary = AudioManager.start_gameplay(_pending_stream)
			if not started.ok:
				_show_error(started.error)
				return
			begin_session(_pending_chart, Callable(AudioManager, "get_song_time_ms"))
		"resume":
			var resumed: Dictionary = AudioManager.resume_gameplay()
			if not resumed.ok:
				_show_error(resumed.error)
				return
			_time_source = Callable(AudioManager, "get_song_time_ms")
			set_process(true)
		"retry":
			var restarted: Dictionary = AudioManager.retry_gameplay()
			if not restarted.ok:
				_show_error(restarted.error)
				return
			retry_session()
			_time_source = Callable(AudioManager, "get_song_time_ms")
			set_process(true)


func _on_session_completed(result: Dictionary) -> void:
	if _finalized_result:
		return
	_finalized_result = true
	AudioManager.stop_gameplay()
	var new_record := false
	if not GameState.selected_song_id.is_empty() and not GameState.selected_difficulty.is_empty():
		var saved: Dictionary = SaveManager.record_high_score(
			GameState.selected_song_id,
			GameState.selected_difficulty,
			int(result.score),
		)
		new_record = bool(saved.get("new_record", false))
	GameState.set_result(result, new_record)
	get_node("/root/ScreenRouter").go_to_results()


func _show_error(message: String) -> void:
	_error_label.text = message
	_error_label.visible = true
	set_process(false)


func _build_product_ui() -> void:
	var stage := UiHelpersScript.panel(Color("1d3b59", 0.75))
	UiHelpersScript.anchor(stage, 0.12, 0.16, 0.88, 0.50)
	add_child(stage)
	var stage_label := UiHelpersScript.label(
		"%s + %s" % [
			GameState.selected_character_id if not GameState.selected_character_id.is_empty() else "PERSONAGEM",
			GameState.selected_table_id if not GameState.selected_table_id.is_empty() else "MESA DJ",
		],
		24,
	)
	UiHelpersScript.anchor(stage_label, 0.10, 0.32, 0.90, 0.62)
	stage.add_child(stage_label)
	_score_label = UiHelpersScript.label("SCORE 0\nCOMBO 0 ×1", 20, HORIZONTAL_ALIGNMENT_LEFT)
	UiHelpersScript.anchor(_score_label, 0.04, 0.03, 0.42, 0.12)
	add_child(_score_label)
	var pause_button := UiHelpersScript.button("PAUSE", 18)
	UiHelpersScript.anchor(pause_button, 0.80, 0.03, 0.96, 0.09)
	pause_button.pressed.connect(pause_session)
	add_child(pause_button)
	_countdown_label = UiHelpersScript.label("3", 72)
	UiHelpersScript.anchor(_countdown_label, 0.25, 0.36, 0.75, 0.50)
	_countdown_label.visible = false
	add_child(_countdown_label)
	_error_label = UiHelpersScript.label("", 22)
	UiHelpersScript.anchor(_error_label, 0.10, 0.25, 0.90, 0.42)
	_error_label.visible = false
	add_child(_error_label)
	_pause_overlay = UiHelpersScript.panel(Color("0b1020", 0.94))
	UiHelpersScript.anchor(_pause_overlay, 0.14, 0.28, 0.86, 0.73)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pause_overlay)
	var pause_title := UiHelpersScript.label("PAUSADO", 36)
	UiHelpersScript.anchor(pause_title, 0.10, 0.08, 0.90, 0.25)
	_pause_overlay.add_child(pause_title)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.01
	volume.value = SaveManager.get_master_volume()
	UiHelpersScript.anchor(volume, 0.16, 0.30, 0.84, 0.40)
	volume.value_changed.connect(func(value: float) -> void:
		SaveManager.set_master_volume(value)
		AudioManager.set_master_volume(value)
	)
	_pause_overlay.add_child(volume)
	var continue_button := UiHelpersScript.button("CONTINUAR")
	UiHelpersScript.anchor(continue_button, 0.18, 0.48, 0.82, 0.60)
	continue_button.pressed.connect(continue_session)
	_pause_overlay.add_child(continue_button)
	var retry_button := UiHelpersScript.button("REINICIAR")
	UiHelpersScript.anchor(retry_button, 0.18, 0.64, 0.82, 0.76)
	retry_button.pressed.connect(retry_product_session)
	_pause_overlay.add_child(retry_button)
	var exit_button := UiHelpersScript.button("SAIR")
	UiHelpersScript.anchor(exit_button, 0.18, 0.80, 0.82, 0.92)
	exit_button.pressed.connect(exit_to_song_select)
	_pause_overlay.add_child(exit_button)
	_pause_overlay.visible = false
