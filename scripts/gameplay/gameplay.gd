class_name Gameplay
extends Control

signal judgments_applied(events: Array[Dictionary])
signal session_completed(result: Dictionary)

const GameplaySessionScript = preload("res://scripts/gameplay/gameplay_session.gd")
const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const ContentValidatorScript = preload("res://scripts/data/content_validator.gd")
const RuntimeChartParserScript = preload("res://scripts/data/runtime_chart_parser.gd")
const PresentationSlotScript = preload("res://scripts/ui/presentation_slot.gd")
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
var _interrupted_countdown_mode := ""
var _pending_chart := {}
var _pending_stream: AudioStream
var _finalized_result := false
var _score_label: Label
var _combo_label: Label
var _miss_label: Label
var _fire_slot: Control
var _character_slot: PresentationSlot
var _table_slot: PresentationSlot
var _countdown_label: Label
var _pause_overlay: Control
var _error_label: Label
var _viewport_guard: ResponsiveViewportGuard

@onready var pad_grid = $PadGrid


func _ready() -> void:
	pad_grid.pad_pressed.connect(_on_pad_pressed)
	pad_grid.pad_released.connect(_on_pad_released)
	session_completed.connect(_on_session_completed)
	_build_product_ui()
	_viewport_guard = UiHelpersScript.attach_viewport_guard(self)
	_viewport_guard.blocking_changed.connect(_on_orientation_blocking_changed)
	set_process(false)
	call_deferred("_begin_selected_song")
	if _viewport_guard.is_blocking():
		call_deferred("_on_orientation_blocking_changed", true)


func _exit_tree() -> void:
	_clear_input_without_forwarding()
	AudioManager.stop_gameplay()


func begin_session(chart: Dictionary, time_source: Callable = Callable()) -> void:
	_chart = chart.duplicate(true)
	_time_source = time_source
	_last_time_ms = 0
	_completion_emitted = false
	_finalized_result = false
	_clear_input_without_forwarding()
	session.start(_chart)
	pad_grid.configure_notes(_chart, session.note_controller)
	_refresh_hud()
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
	_refresh_hud()
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
	_animate_fire()
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
	if _can_accept_gameplay_input():
		press_pad_at(pad, _current_input_time_ms())


func _on_pad_released(pad: int) -> void:
	if _can_accept_gameplay_input():
		release_pad_at(pad, _current_input_time_ms())


func _can_accept_gameplay_input() -> bool:
	return (
		_forward_pad_signals
		and not _countdown_active
		and is_instance_valid(_pause_overlay)
		and not _pause_overlay.visible
		and session.status == GameplaySessionScript.RUNNING
	)


func _clear_input_without_forwarding() -> void:
	_forward_pad_signals = false
	pad_grid.clear_all_sources()
	_forward_pad_signals = true


func _notify_events(events: Array[Dictionary]) -> void:
	if not events.is_empty():
		_refresh_hud()
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
		_interrupt_for_pause()


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
	var loaded_audio: Dictionary = ContentValidatorScript.validate_song_audio(song)
	if not loaded_audio.ok:
		_show_error(loaded_audio.error)
		return
	var duration_validation: Dictionary = ContentValidatorScript.validate_chart_duration(
		parsed.chart,
		song,
		int(loaded_audio.audio_duration_ms),
	)
	if not duration_validation.ok:
		_show_error(duration_validation.error)
		return
	_begin_countdown(parsed.chart, loaded_audio.stream, "start")


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
	if not _interrupted_countdown_mode.is_empty():
		var mode := _interrupted_countdown_mode
		_interrupted_countdown_mode = ""
		if mode == "start":
			_begin_countdown(_pending_chart, _pending_stream, mode)
		else:
			_begin_countdown({}, null, mode)
		return
	_begin_countdown({}, null, "resume")


func retry_product_session() -> void:
	_pause_overlay.visible = false
	if _interrupted_countdown_mode == "start":
		_interrupted_countdown_mode = ""
		_begin_countdown(_pending_chart, _pending_stream, "start")
		return
	_interrupted_countdown_mode = ""
	_begin_countdown({}, null, "retry")


func exit_to_song_select() -> void:
	AudioManager.stop_gameplay()
	stop_session()
	get_node("/root/ScreenRouter").go_to_song_select()


func _begin_countdown(chart: Dictionary, stream: AudioStream, mode: String) -> void:
	_clear_input_without_forwarding()
	if mode == "start":
		_pending_chart = chart.duplicate(true)
		_pending_stream = stream
	elif _pending_chart.is_empty() or _pending_stream == null:
		_show_error("A sessão não possui música válida para reiniciar.")
		return
	_countdown_mode = mode
	_interrupted_countdown_mode = ""
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
	_clear_input_without_forwarding()
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


func _on_orientation_blocking_changed(blocking: bool) -> void:
	if blocking:
		_interrupt_for_pause()


func _interrupt_for_pause() -> void:
	_clear_input_without_forwarding()
	if _countdown_active:
		_interrupted_countdown_mode = _countdown_mode
		_countdown_active = false
		_countdown_label.visible = false
		set_process(false)
		_pause_overlay.visible = true
		return
	if session.status == GameplaySessionScript.RUNNING and not _pause_overlay.visible:
		pause_session()


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
	stage.name = "PresentationStage"
	UiHelpersScript.anchor(stage, 0.12, 0.16, 0.88, 0.50)
	add_child(stage)
	_table_slot = PresentationSlotScript.new("TableSlot", Color("31516f"))
	UiHelpersScript.anchor(_table_slot, 0.08, 0.48, 0.92, 0.92)
	stage.add_child(_table_slot)
	_character_slot = PresentationSlotScript.new("CharacterSlot", Color("4b6680"))
	UiHelpersScript.anchor(_character_slot, 0.28, 0.08, 0.72, 0.72)
	stage.add_child(_character_slot)
	_configure_presentation_slots()
	_fire_slot = PresentationSlotScript.new("ComboFireSlot", Color("f97316", 0.62))
	_fire_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiHelpersScript.anchor(_fire_slot, 0.34, 0.31, 0.66, 0.47)
	_fire_slot.visible = false
	add_child(_fire_slot)
	_combo_label = UiHelpersScript.label("", 28)
	_combo_label.name = "ComboLabel"
	UiHelpersScript.anchor(_combo_label, 0.28, 0.34, 0.72, 0.43)
	_combo_label.visible = false
	add_child(_combo_label)
	_miss_label = UiHelpersScript.label("", 28)
	_miss_label.name = "MissStreakLabel"
	_miss_label.modulate = Color("fb7185")
	UiHelpersScript.anchor(_miss_label, 0.28, 0.43, 0.72, 0.50)
	_miss_label.visible = false
	add_child(_miss_label)
	_score_label = UiHelpersScript.label("SCORE 0", 20, HORIZONTAL_ALIGNMENT_LEFT)
	_score_label.name = "ScoreLabel"
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
	_refresh_hud()


func _configure_presentation_slots() -> void:
	var catalog = ContentCatalogScript.new()
	catalog.load_from_root()
	var character: Dictionary = catalog.get_item(ContentCatalogScript.CATEGORY_CHARACTER, GameState.selected_character_id)
	var table: Dictionary = catalog.get_item(ContentCatalogScript.CATEGORY_TABLE, GameState.selected_table_id)
	var character_item: Dictionary = character.item if character.ok else {}
	var table_item: Dictionary = table.item if table.ok else {}
	_character_slot.configure(
		character_item,
		"visual",
		GameState.selected_character_id if not GameState.selected_character_id.is_empty() else "PERSONAGEM",
	)
	_table_slot.configure(
		table_item,
		"visual",
		GameState.selected_table_id if not GameState.selected_table_id.is_empty() else "MESA DJ",
	)


func _refresh_hud() -> void:
	if not is_instance_valid(_score_label):
		return
	var tracker = session.score_tracker
	_score_label.text = "SCORE %d" % tracker.score
	_combo_label.visible = tracker.combo > 0
	_combo_label.text = "COMBO %d  ×%d" % [tracker.combo, tracker.multiplier] if tracker.combo > 0 else ""
	_miss_label.visible = tracker.miss_streak > 0
	_miss_label.text = "MISS %d" % tracker.miss_streak if tracker.miss_streak > 0 else ""
	_fire_slot.visible = tracker.combo > 0 and tracker.multiplier == 8


func _animate_fire() -> void:
	if not is_instance_valid(_fire_slot) or not _fire_slot.visible:
		return
	_fire_slot.pivot_offset = _fire_slot.size * 0.5
	var pulse := 1.0 + 0.08 * sin(float(Time.get_ticks_msec()) / 90.0)
	_fire_slot.scale = Vector2(pulse, pulse)
