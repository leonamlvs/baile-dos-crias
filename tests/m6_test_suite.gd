extends RefCounted

const CatalogSelectionScript = preload("res://scripts/ui/catalog_selection.gd")
const MemorySaveStoreScript = preload("res://scripts/save/memory_save_store.gd")
const ResponsiveViewportGuardScript = preload("res://scripts/ui/responsive_viewport_guard.gd")
const UiHelpersScript = preload("res://scripts/ui/ui_helpers.gd")
const WebBackupAdapterScript = preload("res://scripts/save/web_backup_adapter.gd")


func run(runner: Object) -> void:
	_test_audio_envelopes(runner)
	_test_responsive_policy(runner)
	_test_selection_hardening(runner)
	_test_screen_composition(runner)
	_test_web_backup_boundary(runner)
	_test_start_data_flow(runner)
	_test_countdown_interruption(runner)
	_test_release_configuration(runner)


func _test_audio_envelopes(runner: Object) -> void:
	var manager = runner.root.get_node("AudioManager")
	runner.expect_equal(manager.beat_phase_at(0, 150.0), 0.0, "Start beat begins at phase zero")
	runner.expect_equal(manager.beat_phase_at(200, 150.0), 0.5, "150 BPM beat phase uses a 400 ms interval")
	runner.expect_equal(manager.beat_phase_at(100, 150.0, 100), 0.0, "Start beat offset aligns the visual phase")
	runner.expect_equal(manager.preview_gain_at(0), 0.0, "preview begins faded out")
	runner.expect_equal(manager.preview_gain_at(125), 0.5, "preview reaches half gain during 250 ms fade-in")
	runner.expect_equal(manager.preview_gain_at(250), 1.0, "preview reaches full gain after 250 ms")
	runner.expect_equal(manager.preview_gain_at(14875), 0.5, "preview fades out over its final 250 ms")
	runner.expect_equal(manager.preview_gain_at(15000), 0.0, "15-second preview loop ends silent")
	runner.expect(not manager.start_start_music(null).ok, "Start music rejects a missing stream")


func _test_responsive_policy(runner: Object) -> void:
	runner.expect(not ResponsiveViewportGuardScript.should_block_for_orientation(Vector2i(720, 1280), true), "portrait mobile remains interactive")
	runner.expect(ResponsiveViewportGuardScript.should_block_for_orientation(Vector2i(1280, 720), true), "landscape mobile requests device rotation")
	runner.expect(not ResponsiveViewportGuardScript.should_block_for_orientation(Vector2i(1280, 720), false), "landscape desktop is letterboxed without a mobile-only overlay")
	var button := UiHelpersScript.button("TEST")
	runner.expect(button.custom_minimum_size.x >= 72.0 and button.custom_minimum_size.y >= 56.0, "shared controls retain mobile-safe minimum targets")
	button.free()


func _test_selection_hardening(runner: Object) -> void:
	runner.expect_equal(CatalogSelectionScript.swipe_direction(47.0), 0, "short selection drag is not a swipe")
	runner.expect_equal(CatalogSelectionScript.swipe_direction(48.0), -1, "right selection swipe moves to previous item")
	runner.expect_equal(CatalogSelectionScript.swipe_direction(-48.0), 1, "left selection swipe moves to next item")
	runner.expect_equal(UiHelpersScript.title_scroll_offset(100.0, 200.0, 20.0), 0.0, "short song title remains static")
	runner.expect(UiHelpersScript.title_scroll_offset(300.0, 200.0, 2.0) > 0.0, "overflowing song title scrolls after its lead-in")


func _test_web_backup_boundary(runner: Object) -> void:
	var adapter = WebBackupAdapterScript.new()
	if not OS.has_feature("web"):
		runner.expect(not adapter.is_supported(), "native build reports browser backup adapter unsupported")
		runner.expect(not adapter.download_json("save.json", "{}").ok, "native build rejects browser download safely")
		runner.expect(not adapter.request_import_file().ok, "native build rejects browser picker safely")


func _test_screen_composition(runner: Object) -> void:
	var character := (load("res://scenes/character_select/character_select.tscn") as PackedScene).instantiate()
	runner.root.add_child(character)
	runner.expect(character.get_node_or_null("ResponsiveViewportGuard") != null, "Character Select attaches the responsive viewport guard")
	runner.expect(character.get_node_or_null("CharacterSwipeArea") != null, "Character track exposes a swipe interaction area")
	runner.expect(character.get_node_or_null("TableSwipeArea") != null, "Table track exposes a swipe interaction area")
	runner.root.remove_child(character)
	character.free()

	var songs := (load("res://scenes/song_select/song_select.tscn") as PackedScene).instantiate()
	runner.root.add_child(songs)
	runner.expect(songs.get_node_or_null("ResponsiveViewportGuard") != null, "Song Select attaches the responsive viewport guard")
	runner.expect(songs.get_node_or_null("PreviousSongCard") != null, "Song queue retains a subdued previous card slot")
	runner.expect(songs.get_node_or_null("FocusedSongCard") != null, "Song queue retains a full-opacity focused card slot")
	runner.expect(songs.get_node_or_null("NextSongCard") != null, "Song queue retains a subdued next card slot")
	runner.expect(
		(songs.get_node("PreviousSongCard") as Control).modulate.a < (songs.get_node("FocusedSongCard") as Control).modulate.a,
		"non-focused song cards remain visually subordinate",
	)
	var title_clip := songs.get_node("FocusedSongCard/SongTitleClip") as Control
	var song_title := title_clip.get_node("SongTitle") as Label
	runner.expect(title_clip.clip_contents and song_title.size.x > title_clip.size.x, "focused song title uses an isolated overflow clip slot")
	runner.root.remove_child(songs)
	songs.free()

	var results := (load("res://scenes/results/results.tscn") as PackedScene).instantiate()
	runner.root.add_child(results)
	runner.expect(results.get_node_or_null("ResponsiveViewportGuard") != null, "Results attaches the responsive viewport guard")
	runner.root.remove_child(results)
	results.free()


func _test_start_data_flow(runner: Object) -> void:
	var save_manager = runner.root.get_node("SaveManager")
	var store = MemorySaveStoreScript.new()
	save_manager.configure_for_testing(store, "memory://m6-save.json")
	save_manager.set_master_volume(0.5)
	var packed := load("res://scenes/start/start.tscn") as PackedScene
	var screen = packed.instantiate()
	screen.enable_start_music = false
	runner.root.add_child(screen)
	var data_button := screen.get_node_or_null("DataButton") as Button
	var modal := screen.get_node_or_null("DataModal") as Control
	runner.expect(data_button != null, "Start exposes a secondary Data control")
	runner.expect(modal != null and not modal.visible, "Data modal starts closed")
	runner.expect(screen.get_node_or_null("ResponsiveViewportGuard") != null, "Start attaches the responsive viewport guard")
	screen.open_data_modal()
	runner.expect(modal.visible, "Data control opens the centered modal")
	screen._on_import_text_received("not-json")
	var confirmation := screen.get_node("DataModal/Dialog/ImportConfirmation") as HBoxContainer
	runner.expect(not confirmation.visible, "invalid backup never reaches replacement confirmation")
	runner.expect((screen.get_node("DataModal/Dialog/DataStatus") as Label).text.contains("Backup rejeitado"), "invalid backup shows an actionable error")
	var before: Dictionary = save_manager.snapshot()
	var valid_export: Dictionary = save_manager.export_json("2026-09-19T00:00:00Z")
	screen._on_import_text_received(valid_export.json)
	runner.expect(confirmation.visible, "valid backup reaches explicit Replace/Cancel confirmation")
	screen._cancel_import()
	runner.expect_equal(save_manager.snapshot(), before, "cancelled Start import leaves current data untouched")
	runner.expect(not confirmation.visible, "Cancel returns to Data menu without replacement")
	var replacement := JSON.stringify({
		"format": "baile-dos-crias-save",
		"version": 1,
		"settings": {"master_volume": 0.25},
		"scores": {"fixture-song": {"easy": 123}},
	})
	screen._on_import_text_received(replacement)
	runner.expect_equal(save_manager.get_master_volume(), 0.5, "validated Start import still waits for Replace")
	screen._confirm_import()
	runner.expect_equal(save_manager.get_master_volume(), 0.25, "Replace applies the validated backup")
	runner.expect_equal(save_manager.get_high_score("fixture-song", "easy"), 123, "Replace persists imported scores")
	runner.expect(store.exists("memory://m6-save.json"), "Replace persists through the save abstraction")
	runner.root.remove_child(screen)
	screen.free()


func _test_countdown_interruption(runner: Object) -> void:
	var packed := load("res://scenes/gameplay/gameplay.tscn") as PackedScene
	var gameplay = packed.instantiate()
	runner.root.add_child(gameplay)
	runner.expect(gameplay.get_node_or_null("ResponsiveViewportGuard") != null, "Gameplay attaches the responsive viewport guard")
	var chart := {
		"version": 1,
		"song_id": "fixture-song",
		"difficulty": "easy",
		"notes": [{"id": "tap", "time_ms": 1000, "pad": 7, "type": "tap"}],
	}
	gameplay.begin_session(chart, func() -> int: return 1000)
	gameplay.set("_pending_chart", chart.duplicate(true))
	gameplay.set("_pending_stream", AudioStreamGenerator.new())
	gameplay.set("_countdown_active", true)
	gameplay.set("_countdown_mode", "resume")
	gameplay._on_pad_pressed(7)
	runner.expect_equal(gameplay.session.score_tracker.judgment_count, 0, "gameplay input is blocked during countdown")
	gameplay._interrupt_for_pause()
	runner.expect(not bool(gameplay.get("_countdown_active")), "focus/orientation interruption stops countdown wall time")
	runner.expect((gameplay.get("_pause_overlay") as Control).visible, "interrupted countdown requires explicit resume")
	gameplay.continue_session()
	runner.expect(bool(gameplay.get("_countdown_active")), "explicit resume restarts a full countdown")
	gameplay.stop_session()
	runner.root.remove_child(gameplay)
	gameplay.free()


func _test_release_configuration(runner: Object) -> void:
	const START_AUDIO := "res://assets/ref/audio/BASE DE FUNK 150 BPM  INSTRUMENTAL  USO LIVRE 03 Prod DIL34N.mp3"
	runner.expect(FileAccess.file_exists(START_AUDIO), "approved Start audio is available for release integration")
	runner.expect(FileAccess.file_exists("res://.github/workflows/validate.yml"), "CI validation workflow exists")
	var workflow := FileAccess.get_file_as_string("res://.github/workflows/validate.yml")
	runner.expect(workflow.contains("GODOT_VERSION: 4.7.2"), "CI pins Godot 4.7.2")
	runner.expect(workflow.contains("--export-release Web"), "CI performs a Web release export")
	runner.expect(FileAccess.file_exists("res://scripts/verify_web_export.py"), "Web artifact verifier exists")
