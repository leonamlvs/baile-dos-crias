extends RefCounted

const CatalogSelectionScript = preload("res://scripts/ui/catalog_selection.gd")
const ScreenRouterScript = preload("res://scripts/screen_router.gd")


func run(runner: Object) -> void:
	_test_screen_router(runner)
	_test_selection_models(runner)
	_test_runtime_state(runner)
	_test_audio_boundaries(runner)


func _test_screen_router(runner: Object) -> void:
	runner.expect_equal(
		ProjectSettings.get_setting("autoload/ScreenRouter"),
		"*res://scripts/screen_router.gd",
		"ScreenRouter is an enabled AutoLoad",
	)
	var router = ScreenRouterScript.new()
	var routes: Array[String] = []
	router.set_navigation_handler_for_testing(func(route: String, _scene_path: String) -> void: routes.append(route))
	runner.expect(router.go_to_song_select(), "ScreenRouter accepts known route")
	runner.expect_equal(routes, ["song_select"], "ScreenRouter delegates only navigation")
	runner.expect(not router.go_to("unknown"), "ScreenRouter rejects unknown route")
	runner.expect(router.last_error.contains("Unknown screen route"), "unknown route has actionable error")
	router.free()


func _test_selection_models(runner: Object) -> void:
	var characters = CatalogSelectionScript.new()
	characters.set_items([{"id": "alpha", "name": "Alpha"}, {"id": "beta", "name": "Beta"}], "beta")
	runner.expect_equal(characters.current_id(), "beta", "selection restores matching runtime ID")
	characters.move(1)
	runner.expect_equal(characters.current_id(), "alpha", "selection wraps forward")
	characters.move(-1)
	runner.expect_equal(characters.current_id(), "beta", "selection wraps backward")

	var songs = CatalogSelectionScript.SongSelection.new()
	songs.set_songs([
		{"id": "one", "difficulties": ["easy", "normal"]},
		{"id": "two", "difficulties": ["hard"]},
	], "one", "normal")
	runner.expect_equal(songs.difficulty, "normal", "song selection restores available difficulty")
	runner.expect(songs.can_continue(), "song selection requires song and difficulty")
	songs.move_song(1)
	runner.expect_equal(songs.difficulty, "", "moving song clears incompatible difficulty")
	runner.expect(not songs.can_continue(), "Next remains disabled until a difficulty is chosen")
	runner.expect(not songs.select_difficulty("normal"), "song selection rejects unavailable difficulty")
	runner.expect(songs.select_difficulty("hard"), "song selection accepts available difficulty")
	runner.expect(songs.can_continue(), "Next enables after difficulty selection")


func _test_runtime_state(runner: Object) -> void:
	var game_state = runner.root.get_node("GameState")
	game_state.set_selected_character("character-a")
	game_state.set_selected_table("table-a")
	game_state.set_selected_song("song-a", "easy")
	game_state.set_result({"score": 123}, true)
	runner.expect_equal(game_state.selected_character_id, "character-a", "cosmetic selection remains runtime state")
	runner.expect_equal(game_state.selected_song_id, "song-a", "selected song is retained for gameplay")
	runner.expect_equal(game_state.selected_difficulty, "easy", "selected difficulty is retained for gameplay")
	runner.expect(game_state.last_new_record, "result context retains new-record outcome")
	game_state.clear_session_context()
	runner.expect(game_state.selected_song_id.is_empty() and game_state.selected_difficulty.is_empty(), "clearing session context drops song selection")
	runner.expect(game_state.last_result.is_empty() and not game_state.last_new_record, "clearing session context drops result data")
	game_state.clear_cosmetic_selection()


func _test_audio_boundaries(runner: Object) -> void:
	var audio_manager = runner.root.get_node("AudioManager")
	runner.expect(not audio_manager.start_preview(null).ok, "preview rejects a missing audio stream")
	runner.expect(not audio_manager.start_gameplay(null).ok, "gameplay rejects a missing audio stream")
	runner.expect(audio_manager.set_master_volume(0.5), "audio manager accepts persisted master volume range")
	runner.expect_equal(audio_manager.get_master_volume(), 0.5, "audio manager retains master volume")
	runner.expect(not audio_manager.set_master_volume(1.1), "audio manager rejects invalid master volume")
	audio_manager.stop_preview()
	runner.expect(not audio_manager.is_preview_playing(), "stopped preview has no active player")
