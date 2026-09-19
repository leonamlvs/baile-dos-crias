extends RefCounted

const ChartPlayerScript = preload("res://scripts/gameplay/chart_player.gd")
const RuntimeChartParserScript = preload("res://scripts/data/runtime_chart_parser.gd")
const SongClockScript = preload("res://scripts/audio/song_clock.gd")


class FakePlaybackSource extends RefCounted:
	var position_seconds := 0.0
	var mix_delta_seconds := 0.0
	var output_latency_seconds := 0.0
	var playing := false
	var paused := false
	var play_count := 0

	func play(from_seconds: float = 0.0) -> void:
		position_seconds = from_seconds
		playing = true
		paused = false
		play_count += 1

	func stop() -> void:
		playing = false
		paused = false
		position_seconds = 0.0

	func is_playing() -> bool:
		return playing

	func get_position_seconds() -> float:
		return position_seconds

	func set_paused(value: bool) -> void:
		paused = value

	func is_paused() -> bool:
		return paused

	func get_mix_delta_seconds() -> float:
		return mix_delta_seconds

	func get_output_latency_seconds() -> float:
		return output_latency_seconds


func run(runner: Object) -> void:
	_test_audio_autoload(runner)
	_test_song_clock(runner)
	_test_chart_parser(runner)
	_test_chart_player(runner)
	_test_clock_and_chart_integration(runner)


func _test_audio_autoload(runner: Object) -> void:
	runner.expect_equal(
		ProjectSettings.get_setting("autoload/AudioManager"),
		"*res://scripts/audio/audio_manager.gd",
		"AudioManager is an enabled AutoLoad",
	)


func _test_song_clock(runner: Object) -> void:
	var source := FakePlaybackSource.new()
	var clock = SongClockScript.new(source)
	runner.expect(clock.start().ok, "song clock starts with playback source")
	source.position_seconds = 1.0
	source.mix_delta_seconds = 0.05
	source.output_latency_seconds = 0.02
	runner.expect_equal(clock.get_time_ms(), 1030, "song clock compensates mix time and output latency")
	source.position_seconds = 0.9
	runner.expect_equal(clock.get_time_ms(), 1030, "song clock remains monotonic when playback sample retreats")
	runner.expect_equal(clock.pause(), 1030, "pause captures authoritative time")
	source.position_seconds = 10.0
	runner.expect_equal(clock.get_time_ms(), 1030, "song clock freezes while paused")
	runner.expect(clock.resume().ok, "song clock resumes from pause")
	source.position_seconds = 1.2
	runner.expect_equal(clock.get_time_ms(), 1230, "song clock continues after resume without accumulated delta")
	source.playing = false
	runner.expect(clock.is_finished(), "song clock reports playback completion")
	runner.expect_equal(clock.get_time_ms(), 1230, "finished song clock preserves final sampled time")
	source.mix_delta_seconds = 0.0
	source.output_latency_seconds = 0.0
	runner.expect(clock.retry().ok, "song clock retry restarts playback")
	runner.expect_equal(clock.get_time_ms(), 0, "song clock retry resets time")
	runner.expect_equal(source.play_count, 2, "song clock retry starts a new playback")
	clock.stop()
	runner.expect_equal(clock.get_time_ms(), 0, "stopped song clock reads zero")


func _test_chart_parser(runner: Object) -> void:
	var parser = RuntimeChartParserScript.new()
	var valid_text := JSON.stringify(_valid_chart_source())
	var valid: Dictionary = parser.parse_text(valid_text, "test-song", "normal")
	runner.expect(valid.ok, "chart parser accepts valid absolute-ms chart")
	runner.expect_equal(valid.chart.notes.size(), 3, "chart parser retains every note")
	runner.expect_equal(valid.chart.notes[2].ticks_ms, [300, 400], "chart parser normalizes Hold ticks")
	runner.expect(not parser.parse_text("not json").ok, "chart parser rejects malformed JSON")
	runner.expect(not parser.parse_file("res://tests/fixtures/missing-chart.json").ok, "chart parser reports missing chart file")
	runner.expect(not parser.parse_text(valid_text, "other-song", "normal").ok, "chart parser rejects song mismatch")
	runner.expect(not parser.parse_text(valid_text, "test-song", "easy").ok, "chart parser rejects difficulty mismatch")

	var empty := _valid_chart_source()
	empty.notes = []
	runner.expect(not parser.validate(empty).ok, "chart parser rejects empty notes")
	var unsupported := _valid_chart_source()
	unsupported.version = 2
	runner.expect(not parser.validate(unsupported).ok, "chart parser rejects unsupported version")
	var invalid_pad := _valid_chart_source()
	invalid_pad.notes[0].pad = 0
	runner.expect(not parser.validate(invalid_pad).ok, "chart parser rejects pad outside 1 through 9")
	var negative_time := _valid_chart_source()
	negative_time.notes[0].time_ms = -1
	runner.expect(not parser.validate(negative_time).ok, "chart parser rejects negative timestamps")
	var unsorted := _valid_chart_source()
	unsorted.notes[1].time_ms = 50
	runner.expect(not parser.validate(unsorted).ok, "chart parser rejects unsorted notes")
	var duplicate := _valid_chart_source()
	duplicate.notes[1].id = duplicate.notes[0].id
	runner.expect(not parser.validate(duplicate).ok, "chart parser rejects duplicate note IDs")
	var invalid_end := _valid_chart_source()
	invalid_end.notes[2].end_ms = 200
	runner.expect(not parser.validate(invalid_end).ok, "chart parser rejects Hold end at start")
	var tick_at_start := _valid_chart_source()
	tick_at_start.notes[2].ticks_ms = [200, 300]
	runner.expect(not parser.validate(tick_at_start).ok, "chart parser rejects Hold tick at start")
	var tick_at_end := _valid_chart_source()
	tick_at_end.notes[2].ticks_ms = [300, 500]
	runner.expect(not parser.validate(tick_at_end).ok, "chart parser rejects Hold tick at exact end")
	var unsorted_ticks := _valid_chart_source()
	unsorted_ticks.notes[2].ticks_ms = [400, 300]
	runner.expect(not parser.validate(unsorted_ticks).ok, "chart parser rejects unsorted Hold ticks")
	var tap_with_hold_fields := _valid_chart_source()
	tap_with_hold_fields.notes[0].end_ms = 500
	runner.expect(not parser.validate(tap_with_hold_fields).ok, "chart parser rejects Hold-only fields on Tap")


func _test_chart_player(runner: Object) -> void:
	var parser = RuntimeChartParserScript.new()
	var parsed: Dictionary = parser.validate(_valid_chart_source())
	var player = ChartPlayerScript.new()
	player.load_chart(parsed.chart)
	runner.expect_equal(player.pending_event_count(), 6, "chart player builds note, tick, and Hold-end events")
	runner.expect_equal(player.advance_to(99).size(), 0, "chart player emits nothing before first timestamp")
	var chord_events: Array[Dictionary] = player.advance_to(100)
	runner.expect_equal(chord_events.size(), 2, "chart player emits simultaneous chord notes together")
	runner.expect_equal(chord_events[0].note.id, "tap-a", "chart player preserves chord source order")
	runner.expect_equal(chord_events[1].note.id, "tap-b", "chart player preserves second chord note")
	var stalled_frame_events: Array[Dictionary] = player.advance_to(450)
	runner.expect_equal(stalled_frame_events.size(), 3, "chart player emits every event crossed by a render stall")
	runner.expect_equal(stalled_frame_events[0].kind, "note", "Hold initial event precedes its ticks")
	runner.expect_equal(stalled_frame_events[1].time_ms, 300, "first Hold tick keeps absolute timestamp")
	runner.expect_equal(stalled_frame_events[2].time_ms, 400, "second Hold tick keeps absolute timestamp")
	var end_events: Array[Dictionary] = player.advance_to(500)
	runner.expect_equal(end_events.size(), 1, "chart player emits Hold end")
	runner.expect_equal(end_events[0].kind, "hold_end", "final event identifies Hold end")
	runner.expect(player.is_exhausted(), "chart player exhausts after final event")
	runner.expect_equal(player.advance_to(400).size(), 0, "chart player rejects backward advance")
	runner.expect(not player.last_error.is_empty(), "backward advance reports actionable error")
	player.reset()
	runner.expect_equal(player.advance_to(100).size(), 2, "chart player reset starts a clean retry")


func _test_clock_and_chart_integration(runner: Object) -> void:
	var source := FakePlaybackSource.new()
	var clock = SongClockScript.new(source)
	var parser = RuntimeChartParserScript.new()
	var parsed: Dictionary = parser.validate(_valid_chart_source())
	var player = ChartPlayerScript.new()
	player.load_chart(parsed.chart)
	clock.start()
	source.position_seconds = 0.1
	runner.expect_equal(player.advance_to(clock.get_time_ms()).size(), 2, "chart traversal follows song time")
	clock.pause()
	source.position_seconds = 5.0
	runner.expect_equal(player.advance_to(clock.get_time_ms()).size(), 0, "paused song clock cannot advance chart")
	clock.resume()
	source.position_seconds = 0.5
	runner.expect_equal(player.advance_to(clock.get_time_ms()).size(), 4, "resume catches every due chart event without drift")
	clock.retry()
	player.reset()
	source.position_seconds = 0.1
	runner.expect_equal(player.advance_to(clock.get_time_ms()).size(), 2, "retry resets clock and chart together")


func _valid_chart_source() -> Dictionary:
	return {
		"version": 1,
		"song_id": "test-song",
		"difficulty": "normal",
		"notes": [
			{"id": "tap-a", "time_ms": 100, "pad": 7, "type": "tap"},
			{"id": "tap-b", "time_ms": 100, "pad": 8, "type": "tap"},
			{
				"id": "hold-a",
				"time_ms": 200,
				"pad": 5,
				"type": "hold",
				"end_ms": 500,
				"ticks_ms": [300, 400],
			},
		],
	}
