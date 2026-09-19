extends SceneTree

const EXPECTED_SCENES: Array[String] = [
	"res://scenes/start/start.tscn",
	"res://scenes/character_select/character_select.tscn",
	"res://scenes/song_select/song_select.tscn",
	"res://scenes/gameplay/gameplay.tscn",
	"res://scenes/results/results.tscn",
]
const M1TestSuite = preload("res://tests/m1_test_suite.gd")
const M2TestSuite = preload("res://tests/m2_test_suite.gd")

var _failures := 0
var _checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("M0/M1/M2 validation started")
	_check_project_settings()
	_check_scenes()
	_check_web_preset()
	M1TestSuite.new().run(self)
	M2TestSuite.new().run(self)

	if _failures == 0:
		print("M0/M1/M2 validation passed: %d checks" % _checks)
		quit(0)
		return

	printerr("M0/M1/M2 validation failed: %d of %d checks failed" % [_failures, _checks])
	quit(1)


func _check_project_settings() -> void:
	_expect_equal(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		720,
		"logical viewport width",
	)
	_expect_equal(
		ProjectSettings.get_setting("display/window/size/viewport_height"),
		1280,
		"logical viewport height",
	)
	_expect_equal(
		ProjectSettings.get_setting("display/window/stretch/mode"),
		"canvas_items",
		"uniform canvas scaling mode",
	)
	_expect_equal(
		ProjectSettings.get_setting("display/window/stretch/aspect"),
		"keep",
		"non-cropping stretch aspect",
	)
	_expect_equal(
		ProjectSettings.get_setting("display/window/handheld/orientation"),
		1,
		"portrait handheld orientation",
	)
	_expect_equal(
		ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"gl_compatibility",
		"desktop Compatibility renderer",
	)
	_expect_equal(
		ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"),
		"gl_compatibility",
		"mobile Compatibility renderer",
	)
	_expect_equal(
		ProjectSettings.get_setting("application/run/main_scene"),
		"res://scenes/start/start.tscn",
		"main scene",
	)


func _check_scenes() -> void:
	for scene_path in EXPECTED_SCENES:
		var resource := load(scene_path) as PackedScene
		_expect(resource != null, "load %s" % scene_path)
		if resource == null:
			continue

		var instance := resource.instantiate()
		_expect(instance != null, "instantiate %s" % scene_path)
		if instance == null:
			continue

		_expect(instance is Control, "%s root is Control" % scene_path)
		_expect(instance.get_script() == null, "%s remains behavior-free" % scene_path)
		_expect(instance.get_child_count() == 0, "%s remains a placeholder" % scene_path)
		instance.free()


func _check_web_preset() -> void:
	const PRESET_PATH := "res://export_presets.cfg"
	_expect(FileAccess.file_exists(PRESET_PATH), "Web export preset file exists")
	if not FileAccess.file_exists(PRESET_PATH):
		return

	var preset_text := FileAccess.get_file_as_string(PRESET_PATH)
	_expect(preset_text.contains('name="Web"'), "Web preset is named Web")
	_expect(preset_text.contains('platform="Web"'), "Web preset targets Web")
	_expect(
		preset_text.contains('export_path="build/web/index.html"'),
		"Web preset has expected output path",
	)
	_expect(
		preset_text.contains('exclude_filter="build/*,tests/*,assets/ref/*"'),
		"Web preset excludes local builds, tests, and reference-only assets",
	)


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS: %s" % label)
		return

	_failures += 1
	printerr("FAIL: %s" % label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect(actual == expected, "%s (expected %s, got %s)" % [label, expected, actual])


func expect(condition: bool, label: String) -> void:
	_expect(condition, label)


func expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect_equal(actual, expected, label)
