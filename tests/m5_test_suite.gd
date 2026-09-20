extends RefCounted

const RuntimeChartParserScript = preload("res://scripts/data/runtime_chart_parser.gd")

func run(runner: Object) -> void:
	runner.expect(
		FileAccess.file_exists("res://tools/chart_import/midi_to_json.py"),
		"M5 MIDI importer CLI exists",
	)
	runner.expect(
		FileAccess.file_exists("res://tools/chart_import/example-config.json"),
		"M5 example nine-pad mapping exists",
	)
	var project_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var output: Array = []
	var exit_code := OS.execute(
		"python",
		PackedStringArray([
			"-m", "unittest", "discover",
			"-s", project_root.path_join("tools/chart_import/tests"),
			"-t", project_root,
			"-v",
		]),
		output,
		true,
	)
	var report := "\n".join(output)
	runner.expect_equal(exit_code, 0, "M5 Python importer tests exit successfully")
	runner.expect(report.contains("Ran 13 tests") and report.contains("OK"), "M5 Python importer reports all deterministic tests")
	var parsed: Dictionary = RuntimeChartParserScript.new().parse_file(
		"res://tests/fixtures/chart_import/expected-variable-tempo.json",
		"tempo-song",
		"easy",
	)
	runner.expect(parsed.ok, "Godot runtime parser accepts M5-generated chart shape")
	if parsed.ok:
		runner.expect_equal(parsed.chart.notes[0].ticks_ms, [500], "M5 Hold ticks retain strict tempo-aware timestamps")
