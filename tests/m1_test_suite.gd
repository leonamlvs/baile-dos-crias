extends RefCounted

const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const InputRouterScript = preload("res://scripts/input/input_router.gd")
const MemorySaveStoreScript = preload("res://scripts/save/memory_save_store.gd")
const SaveManagerScript = preload("res://scripts/save/save_manager.gd")


func run(runner: Object) -> void:
	_test_autoloads(runner)
	_test_content_catalog(runner)
	_test_save_manager(runner)
	_test_input_router(runner)



func _test_autoloads(runner: Object) -> void:
	runner.expect_equal(
		ProjectSettings.get_setting("autoload/GameState"),
		"*res://scripts/game_state.gd",
		"GameState is an enabled AutoLoad",
	)
	runner.expect_equal(
		ProjectSettings.get_setting("autoload/SaveManager"),
		"*res://scripts/save/save_manager.gd",
		"SaveManager is an enabled AutoLoad",
	)


func _test_content_catalog(runner: Object) -> void:
	var catalog = ContentCatalogScript.new()
	catalog.load_from_root("res://tests/fixtures/content")
	runner.expect_equal(catalog.songs.size(), 2, "catalog loads valid songs despite invalid contributions")
	if catalog.songs.size() >= 2:
		runner.expect_equal(catalog.songs[0].id, "alpha-song", "catalog sorts songs by stable ID")
		runner.expect_equal(catalog.songs[1].id, "zulu-song", "catalog retains later valid song")
	runner.expect_equal(catalog.characters.size(), 1, "catalog loads valid character metadata")
	runner.expect_equal(catalog.tables.size(), 1, "catalog excludes invalid table metadata")
	runner.expect(catalog.diagnostics.size() >= 4, "catalog returns actionable diagnostics per invalid item")
	runner.expect(catalog.get_item("songs", "alpha-song").ok, "catalog resolves valid item")
	var invalid_lookup: Dictionary = catalog.get_item("songs", "broken-song")
	runner.expect(not invalid_lookup.ok and invalid_lookup.error.contains("invalid and excluded"), "catalog explains invalid item lookup")
	var missing_lookup: Dictionary = catalog.get_item("songs", "missing-song")
	runner.expect(not missing_lookup.ok and missing_lookup.error.contains("not found"), "catalog explains missing item lookup")


func _test_save_manager(runner: Object) -> void:
	var store = MemorySaveStoreScript.new()
	var manager = SaveManagerScript.new()
	manager.configure_for_testing(store, "memory://save.json")
	var missing_result: Dictionary = manager.load_local()
	runner.expect_equal(missing_result.status, "missing", "missing save starts from defaults")
	runner.expect_equal(manager.get_master_volume(), 1.0, "default master volume is one")
	runner.expect_equal(manager.snapshot().scores.size(), 0, "default save has no scores")
	runner.expect(not manager.snapshot().has("selection"), "save-v1 excludes cosmetic selection")
	runner.expect(not manager.set_master_volume(1.1).ok, "save rejects volume above one")
	runner.expect(manager.set_master_volume(0.5).ok, "save accepts bounded volume")
	runner.expect(manager.record_high_score("alpha-song", "easy", 100).new_record, "first score is a new record")
	runner.expect(not manager.record_high_score("alpha-song", "easy", 100).new_record, "equal score is not a new record")
	runner.expect(not manager.record_high_score("alpha-song", "easy", 99).new_record, "lower score is not a new record")
	runner.expect_equal(manager.get_high_score("alpha-song", "easy"), 100, "save returns best score")
	runner.expect(manager.persist().ok, "save persists through injected store")

	var export_result: Dictionary = manager.export_json("2026-09-19T00:00:00Z")
	var export_json := JSON.new()
	runner.expect_equal(export_json.parse(export_result.json), OK, "export emits JSON")
	runner.expect_equal(export_json.data.exported_at, "2026-09-19T00:00:00Z", "export adds timestamp")
	runner.expect_equal(export_result.filename, "baile-dos-crias-save-v1.json", "export uses versioned filename")

	var import_text := JSON.stringify({
		"format": "baile-dos-crias-save",
		"version": 1,
		"settings": {"master_volume": 0.25},
		"scores": {"zulu-song": {"normal": 250}},
	})
	var pending: Dictionary = manager.prepare_import(import_text)
	runner.expect(pending.ok, "valid import prepares a pending candidate")
	runner.expect_equal(manager.get_master_volume(), 0.5, "pending import does not mutate save")
	runner.expect(not manager.confirm_import("wrong-token").ok, "wrong import token cannot replace save")
	runner.expect(manager.confirm_import(pending.token).ok, "confirmed import replaces save")
	runner.expect_equal(manager.get_master_volume(), 0.25, "confirmed import applies settings")
	runner.expect_equal(manager.get_high_score("zulu-song", "normal"), 250, "confirmed import applies scores")

	var invalid_store = MemorySaveStoreScript.new()
	invalid_store.files["memory://invalid.json"] = "not json"
	var invalid_manager = SaveManagerScript.new()
	invalid_manager.configure_for_testing(invalid_store, "memory://invalid.json")
	runner.expect_equal(invalid_manager.load_local().status, "invalid", "malformed save is invalid")
	runner.expect(not invalid_store.exists("memory://invalid.json"), "malformed save is removed from active path")
	runner.expect_equal(invalid_store.renamed_paths.size(), 1, "malformed save is quarantined")
	runner.expect_equal(invalid_manager.get_master_volume(), 1.0, "invalid save falls back to in-memory defaults")

	var unsupported_store = MemorySaveStoreScript.new()
	unsupported_store.files["memory://unsupported.json"] = JSON.stringify({
		"format": "baile-dos-crias-save",
		"version": 2,
		"settings": {"master_volume": 0.5},
		"scores": {},
	})
	var unsupported_manager = SaveManagerScript.new()
	unsupported_manager.configure_for_testing(unsupported_store, "memory://unsupported.json")
	runner.expect_equal(unsupported_manager.load_local().status, "unsupported", "future save version is unsupported")
	runner.expect(unsupported_store.exists("memory://unsupported.json"), "unsupported save remains untouched")
	runner.expect_equal(unsupported_store.renamed_paths.size(), 0, "unsupported save is not quarantined")
	manager.free()
	invalid_manager.free()
	unsupported_manager.free()


func _test_input_router(runner: Object) -> void:
	var router = InputRouterScript.new()
	var pressed: Array[int] = []
	var released: Array[int] = []
	router.pad_pressed.connect(func(pad: int) -> void: pressed.append(pad))
	router.pad_released.connect(func(pad: int) -> void: released.append(pad))

	var q_press := _key_event(KEY_Q, true)
	var q_release := _key_event(KEY_Q, false)
	var kp7_press := _key_event(KEY_KP_7, true)
	var kp7_release := _key_event(KEY_KP_7, false)
	runner.expect(router.handle_key_event(q_press), "Q begins pad 7")
	runner.expect(router.handle_key_event(kp7_press), "KP7 joins pad 7")
	runner.expect_equal(pressed, [7], "equivalent keys emit one logical press")
	runner.expect(router.handle_key_event(q_release), "Q source releases")
	runner.expect_equal(released.size(), 0, "pad remains held while equivalent source remains")
	runner.expect(router.handle_key_event(kp7_release), "KP7 source releases")
	runner.expect_equal(released, [7], "final equivalent source emits logical release")

	runner.expect(router.begin_touch(1, 5), "first touch begins on pad 5")
	runner.expect(router.begin_touch(2, 9), "second touch begins on pad 9")
	runner.expect_equal(router.get_touch_pad(1), 5, "touch remains bound to initial pad")
	runner.expect(not router.begin_touch(1, 6), "touch cannot transfer to another pad")
	runner.expect(router.begin_mouse(MOUSE_BUTTON_LEFT, 1), "mouse may chord with touches")
	runner.expect(router.is_pad_held(5) and router.is_pad_held(9) and router.is_pad_held(1), "router supports chords")
	router.clear_all_sources()
	runner.expect(not router.is_pad_held(5) and not router.is_pad_held(9) and not router.is_pad_held(1), "focus clear releases every active source")
	runner.expect(released.has(5) and released.has(9) and released.has(1), "focus clear emits logical releases")


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event
