extends RefCounted

const GameplaySessionScript = preload("res://scripts/gameplay/gameplay_session.gd")
const JudgmentRulesScript = preload("res://scripts/gameplay/judgment_rules.gd")
const NoteControllerScript = preload("res://scripts/gameplay/note_controller.gd")
const NoteVisualStateScript = preload("res://scripts/gameplay/note_visual_state.gd")
const PadGridScript = preload("res://scripts/gameplay/pad_grid.gd")
const ScoreTrackerScript = preload("res://scripts/gameplay/score_tracker.gd")


func run(runner: Object) -> void:
	_test_judgment_boundaries(runner)
	_test_note_visual_timing(runner)
	_test_pad_grid(runner)
	_test_combo_score_and_multiplier(runner)
	_test_miss_streak(runner)
	_test_accuracy_and_rank(runner)
	_test_tap_lifecycle(runner)
	_test_hold_lifecycle(runner)
	_test_chords_and_overlap(runner)
	_test_session_completion_and_reset(runner)


func _test_judgment_boundaries(runner: Object) -> void:
	var cases := [
		[0, "PERFECT"],
		[50, "PERFECT"],
		[51, "GREAT"],
		[100, "GREAT"],
		[101, "GOOD"],
		[150, "GOOD"],
		[151, "BAD"],
		[220, "BAD"],
		[221, "MISS"],
	]
	for item in cases:
		var delta_ms := int(item[0])
		var expected := String(item[1])
		runner.expect_equal(
			JudgmentRulesScript.classify(delta_ms),
			expected,
			"late +%d ms is %s" % [delta_ms, expected],
		)
		if delta_ms > 0:
			runner.expect_equal(
				JudgmentRulesScript.classify(-delta_ms),
				expected,
				"early -%d ms is %s" % [delta_ms, expected],
			)
	runner.expect_equal(JudgmentRulesScript.base_points("PERFECT"), 100, "PERFECT base value")
	runner.expect_equal(JudgmentRulesScript.base_points("GREAT"), 75, "GREAT base value")
	runner.expect_equal(JudgmentRulesScript.base_points("GOOD"), 50, "GOOD base value")
	runner.expect_equal(JudgmentRulesScript.base_points("BAD"), 10, "BAD base value")
	runner.expect_equal(JudgmentRulesScript.base_points("MISS"), 0, "MISS base value")


func _test_note_visual_timing(runner: Object) -> void:
	runner.expect_equal(NoteVisualStateScript.approach_progress(0, 1000, 1000), 0.0, "note starts at center scale")
	runner.expect_equal(NoteVisualStateScript.approach_progress(500, 1000, 1000), 0.5, "note expands proportionally")
	runner.expect_equal(NoteVisualStateScript.approach_progress(1000, 1000, 1000), 1.0, "note reaches target size exactly at hit time")
	runner.expect_equal(NoteVisualStateScript.approach_progress(1200, 1000, 1000), 1.0, "approach progress clamps after hit")
	runner.expect_equal(NoteVisualStateScript.hold_progress(1000, 1000, 1400), 0.0, "Hold progress starts at hit time")
	runner.expect_equal(NoteVisualStateScript.hold_progress(1200, 1000, 1400), 0.5, "Hold progress follows authoritative time")
	runner.expect_equal(NoteVisualStateScript.hold_progress(1400, 1000, 1400), 1.0, "Hold progress completes exactly at end")


func _test_pad_grid(runner: Object) -> void:
	var grid = PadGridScript.new()
	grid.size = Vector2(308.0, 308.0)
	grid.gutter = 4.0
	runner.expect_equal(grid.pad_at_position(Vector2(50.0, 50.0)), 7, "pad grid top-left maps to logical pad 7")
	runner.expect_equal(grid.pad_at_position(Vector2(154.0, 50.0)), 8, "pad grid top-center maps to logical pad 8")
	runner.expect_equal(grid.pad_at_position(Vector2(258.0, 50.0)), 9, "pad grid top-right maps to logical pad 9")
	runner.expect_equal(grid.pad_at_position(Vector2(50.0, 154.0)), 4, "pad grid middle-left maps to logical pad 4")
	runner.expect_equal(grid.pad_at_position(Vector2(154.0, 154.0)), 5, "pad grid center maps to logical pad 5")
	runner.expect_equal(grid.pad_at_position(Vector2(258.0, 258.0)), 3, "pad grid bottom-right maps to logical pad 3")
	runner.expect_equal(grid.pad_at_position(Vector2(101.0, 50.0)), 0, "pad grid gutter is not an input target")
	runner.expect_equal(grid.pad_at_position(Vector2(-1.0, 50.0)), 0, "pad grid rejects positions outside bounds")
	runner.expect_equal(grid.rect_for_pad(1).get_center(), Vector2(50.0, 258.0), "pad 1 geometry is bottom-left")
	runner.expect_equal(grid.rect_for_pad(9).get_center(), Vector2(258.0, 50.0), "pad 9 geometry is top-right")
	grid.free()


func _test_combo_score_and_multiplier(runner: Object) -> void:
	var tracker = ScoreTrackerScript.new()
	for index in range(9):
		tracker.apply_judgment("PERFECT")
	runner.expect_equal(tracker.combo, 9, "first nine positive judgments remain x1")
	runner.expect_equal(tracker.score, 900, "first nine PERFECT judgments score at x1")
	var tenth: Dictionary = tracker.apply_judgment("PERFECT")
	runner.expect_equal(tenth.multiplier, 2, "combo 10 uses x2 immediately")
	runner.expect_equal(tenth.awarded_points, 200, "threshold-reaching combo 10 scores at x2")
	for index in range(9):
		tracker.apply_judgment("GREAT")
	var twentieth: Dictionary = tracker.apply_judgment("GOOD")
	runner.expect_equal(twentieth.multiplier, 4, "combo 20 uses x4 immediately")
	runner.expect_equal(twentieth.awarded_points, 200, "GOOD at combo 20 uses base 50 times x4")
	for index in range(9):
		tracker.apply_judgment("PERFECT")
	var thirtieth: Dictionary = tracker.apply_judgment("PERFECT")
	runner.expect_equal(thirtieth.multiplier, 6, "combo 30 uses x6 immediately")
	for index in range(9):
		tracker.apply_judgment("PERFECT")
	var fortieth: Dictionary = tracker.apply_judgment("PERFECT")
	runner.expect_equal(fortieth.multiplier, 8, "combo 40 uses x8 immediately")
	var forty_first: Dictionary = tracker.apply_judgment("PERFECT")
	runner.expect_equal(forty_first.multiplier, 8, "multiplier remains capped at x8")
	runner.expect_equal(tracker.max_combo, 41, "maximum positive combo is retained")
	var bad: Dictionary = tracker.apply_judgment("BAD")
	runner.expect_equal(bad.combo, 0, "BAD breaks positive combo")
	runner.expect_equal(bad.multiplier, 1, "BAD clears active multiplier")
	runner.expect_equal(bad.awarded_points, 10, "BAD scores base points at x1 after break")
	runner.expect_equal(tracker.max_combo, 41, "combo break does not erase maximum combo")
	var after_break: Dictionary = tracker.apply_judgment("PERFECT")
	runner.expect_equal(after_break.combo, 1, "positive combo restarts after a break")
	runner.expect_equal(after_break.awarded_points, 100, "restarted combo scores at x1")
	var miss: Dictionary = tracker.apply_judgment("MISS")
	runner.expect_equal(miss.combo, 0, "MISS breaks positive combo")
	runner.expect_equal(miss.multiplier, 1, "MISS clears active multiplier")
	var rejected: Dictionary = tracker.apply_judgment("UNKNOWN")
	runner.expect(not rejected.ok, "unknown judgment is rejected without mutation")
	runner.expect_equal(tracker.judgment_count, 44, "rejected judgment does not increment count")


func _test_miss_streak(runner: Object) -> void:
	var tracker = ScoreTrackerScript.new()
	for index in range(49):
		tracker.apply_judgment("MISS")
	runner.expect_equal(tracker.miss_streak, 49, "49 consecutive MISS judgments remain playable")
	runner.expect(not tracker.failed, "failure does not trigger before 50 MISS judgments")
	tracker.apply_judgment("BAD")
	runner.expect_equal(tracker.miss_streak, 0, "BAD resets MISS streak despite breaking combo")
	for judgment in ["GOOD", "GREAT", "PERFECT"]:
		tracker.apply_judgment("MISS")
		tracker.apply_judgment(judgment)
		runner.expect_equal(tracker.miss_streak, 0, "%s resets MISS streak" % judgment)
	tracker.reset()
	for index in range(50):
		tracker.apply_judgment("MISS")
	runner.expect_equal(tracker.miss_streak, 50, "MISS streak reaches exact failure boundary")
	runner.expect(tracker.failed, "50 consecutive MISS judgments trigger failure")


func _test_accuracy_and_rank(runner: Object) -> void:
	var empty = ScoreTrackerScript.new()
	runner.expect_equal(empty.get_accuracy(), 0.0, "empty result accuracy is zero")
	runner.expect_equal(empty.get_rank(), "F", "empty result rank is F")

	var s_rank = _tracker_with_counts(95, 5, 0, 0, 0)
	runner.expect_equal(s_rank.get_accuracy(), 98.75, "accuracy uses unmultiplied base points")
	runner.expect_equal(s_rank.get_rank(), "S", "S permits only PERFECT and GREAT at or above 95 percent")
	var s_disqualified = _tracker_with_counts(99, 0, 1, 0, 0)
	runner.expect(s_disqualified.get_accuracy() >= 95.0, "S-disqualification fixture exceeds 95 percent")
	runner.expect_equal(s_disqualified.get_rank(), "A", "GOOD disqualifies S even above 95 percent")
	runner.expect_equal(_tracker_with_counts(90, 0, 0, 0, 10).get_rank(), "A", "90 percent is rank A")
	runner.expect_equal(_tracker_with_counts(80, 0, 0, 0, 20).get_rank(), "B", "80 percent is rank B")
	runner.expect_equal(_tracker_with_counts(70, 0, 0, 0, 30).get_rank(), "C", "70 percent is rank C")
	runner.expect_equal(_tracker_with_counts(60, 0, 0, 0, 40).get_rank(), "D", "60 percent is rank D")
	runner.expect_equal(_tracker_with_counts(59, 0, 0, 0, 41).get_rank(), "F", "below 60 percent is rank F")
	var multiplied = _tracker_with_counts(10, 0, 0, 0, 0)
	runner.expect_equal(multiplied.score, 1100, "combo multiplier affects score")
	runner.expect_equal(multiplied.earned_base_points, 1000, "combo multiplier does not affect accuracy numerator")
	runner.expect_equal(multiplied.get_accuracy(), 100.0, "accuracy remains independent of multiplier")


func _test_tap_lifecycle(runner: Object) -> void:
	var early = NoteControllerScript.new()
	early.load_chart(_chart([_tap("tap", 1000, 1)]))
	var early_events: Array[Dictionary] = early.press_pad(1, 780)
	runner.expect_equal(early_events[0].judgment, "BAD", "Tap is hittable at exact early -220 ms boundary")

	var late = NoteControllerScript.new()
	late.load_chart(_chart([_tap("tap", 1000, 1)]))
	var late_events: Array[Dictionary] = late.press_pad(1, 1220)
	runner.expect_equal(late_events[0].judgment, "BAD", "Tap is hittable at exact late +220 ms boundary")

	var expired = NoteControllerScript.new()
	expired.load_chart(_chart([_tap("tap", 1000, 1)]))
	runner.expect_equal(expired.advance_to(1220).size(), 0, "Tap does not MISS at exact +220 ms boundary")
	var miss_events: Array[Dictionary] = expired.advance_to(1221)
	runner.expect_equal(miss_events.size(), 1, "unhit Tap expires once after the hit window")
	runner.expect_equal(miss_events[0].judgment, "MISS", "expired Tap becomes MISS")

	var held = NoteControllerScript.new()
	held.load_chart(_chart([_tap("tap-a", 1000, 4), _tap("tap-b", 1300, 4)]))
	runner.expect_equal(held.press_pad(4, 1000).size(), 1, "new press hits first Tap")
	runner.expect_equal(held.press_pad(4, 1300).size(), 0, "held pad does not create another Tap transition")
	var held_miss: Array[Dictionary] = held.advance_to(1521)
	runner.expect_equal(held_miss.size(), 1, "blocked Tap later expires exactly once")
	runner.expect_equal(held_miss[0].note_id, "tap-b", "held transition cannot consume later Tap")

	var repress = NoteControllerScript.new()
	repress.load_chart(_chart([_tap("tap-a", 1000, 4), _tap("tap-b", 1300, 4)]))
	repress.press_pad(4, 1000)
	repress.release_pad(4, 1100)
	var repress_events: Array[Dictionary] = repress.press_pad(4, 1300)
	runner.expect_equal(repress_events[0].note_id, "tap-b", "release then press can hit a later Tap")
	runner.expect(repress.all_notes_complete(), "judged Tap notes complete their lifecycle")
	runner.expect_equal(repress.advance_to(1200).size(), 0, "backward note time is rejected")
	runner.expect(not repress.last_error.is_empty(), "backward note time reports an error")


func _test_hold_lifecycle(runner: Object) -> void:
	var controller = NoteControllerScript.new()
	controller.load_chart(_chart([_hold("hold", 1000, 5, 1400, [1100, 1200, 1300])]))
	runner.expect_equal(controller.press_pad(5, 0).size(), 0, "far-early Hold press does not score immediately")
	var initial: Array[Dictionary] = controller.advance_to(1000)
	runner.expect_equal(initial[0].judgment, "PERFECT", "pre-held Hold initial is PERFECT at hit time")
	var first_tick: Array[Dictionary] = controller.advance_to(1100)
	runner.expect_equal(first_tick[0].judgment, "PERFECT", "held Hold tick is PERFECT")
	var released_tick: Array[Dictionary] = controller.release_pad(5, 1200)
	runner.expect_equal(released_tick[0].judgment, "MISS", "release exactly at Hold tick makes that tick MISS")
	var resumed_tick: Array[Dictionary] = controller.press_pad(5, 1300)
	runner.expect_equal(resumed_tick[0].judgment, "PERFECT", "press exactly at later Hold tick resumes scoring")
	runner.expect_equal(controller.advance_to(1400).size(), 0, "Hold end is not a scoring tick")
	var state: Dictionary = controller.get_note_state("hold")
	runner.expect_equal(state.ticks_processed, 3, "every explicit Hold tick is processed once")
	runner.expect(state.ended, "Hold lifecycle ends at end_ms")
	runner.expect(controller.all_notes_complete(), "Hold completes only after its end event")

	var regular = NoteControllerScript.new()
	regular.load_chart(_chart([_hold("hold", 1000, 5, 1400, [])]))
	var regular_hit: Array[Dictionary] = regular.press_pad(5, 1100)
	runner.expect_equal(regular_hit[0].judgment, "GREAT", "normal Hold press uses the common timing table")

	var missing = NoteControllerScript.new()
	missing.load_chart(_chart([_hold("hold", 1000, 5, 1400, [])]))
	runner.expect_equal(missing.advance_to(1220).size(), 0, "unstarted Hold remains hittable at +220 ms")
	var missing_events: Array[Dictionary] = missing.advance_to(1221)
	runner.expect_equal(missing_events[0].judgment, "MISS", "unstarted Hold expires after +220 ms")

	var stalled = NoteControllerScript.new()
	stalled.load_chart(_chart([_hold("hold", 1000, 5, 1400, [1100, 1200, 1300])]))
	stalled.press_pad(5, 0)
	var stalled_events: Array[Dictionary] = stalled.advance_to(1300)
	runner.expect_equal(stalled_events.size(), 4, "render stall catches Hold start and every crossed tick")
	runner.expect_equal(stalled_events[0].source, "initial", "stalled Hold start remains first")
	runner.expect_equal(stalled_events[3].time_ms, 1300, "stalled Hold ticks preserve final absolute timestamp")

	var scoring_session = GameplaySessionScript.new()
	scoring_session.start(_chart([_hold("hold", 1000, 5, 1400, [1100, 1200, 1300])]))
	scoring_session.press_pad(5, 1000)
	scoring_session.advance_to(1100)
	scoring_session.release_pad(5, 1200)
	runner.expect_equal(scoring_session.score_tracker.counts.MISS, 1, "released Hold tick contributes to MISS statistics")
	runner.expect_equal(scoring_session.score_tracker.miss_streak, 1, "released Hold tick increments MISS streak")
	scoring_session.press_pad(5, 1300)
	runner.expect_equal(scoring_session.score_tracker.counts.PERFECT, 3, "held Hold ticks contribute PERFECT statistics")
	runner.expect_equal(scoring_session.score_tracker.miss_streak, 0, "resumed Hold PERFECT resets MISS streak")
	runner.expect_equal(scoring_session.score_tracker.get_accuracy(), 75.0, "Hold initial and ticks all contribute to accuracy")


func _test_chords_and_overlap(runner: Object) -> void:
	var session = GameplaySessionScript.new()
	session.start(_chart([
		_tap("chord-a", 1000, 7),
		_tap("chord-b", 1000, 8),
		_hold("hold", 1000, 5, 1300, [1100, 1200]),
		_tap("overlap", 1100, 6),
	]))
	runner.expect_equal(session.press_pad(7, 1000).size(), 1, "first chord lane judges independently")
	runner.expect_equal(session.press_pad(8, 1000).size(), 1, "second chord lane judges at same timestamp")
	runner.expect_equal(session.press_pad(5, 1000).size(), 1, "Hold can start alongside chord")
	var overlap_events: Array[Dictionary] = session.press_pad(6, 1100)
	runner.expect_equal(overlap_events.size(), 2, "Hold tick and overlapping Tap both score at same timestamp")
	runner.expect_equal(session.score_tracker.judgment_count, 5, "chord, Hold start, tick, and Tap are separate judgments")
	session.advance_to(1200)
	runner.expect_equal(session.score_tracker.judgment_count, 6, "later Hold tick contributes to statistics")
	runner.expect_equal(session.score_tracker.combo, 6, "PERFECT Hold ticks build positive combo")


func _test_session_completion_and_reset(runner: Object) -> void:
	var forty_nine = GameplaySessionScript.new()
	forty_nine.start(_chart(_tap_sequence(49)))
	forty_nine.advance_to(10000)
	runner.expect_equal(forty_nine.status, GameplaySessionScript.RUNNING, "49 lifecycle MISS judgments do not fail session")
	var successful_result: Dictionary = forty_nine.finish_song(10000)
	runner.expect_equal(successful_result.status, GameplaySessionScript.SUCCESS, "song end without 50 consecutive MISS is success")

	var fifty = GameplaySessionScript.new()
	fifty.start(_chart(_tap_sequence(50)))
	fifty.advance_to(10000)
	runner.expect_equal(fifty.status, GameplaySessionScript.FAILURE, "50th lifecycle MISS ends session as failure")
	runner.expect_equal(fifty.score_tracker.judgment_count, 50, "failure occurs on exact 50th MISS")
	runner.expect_equal(fifty.press_pad(1, 10001).size(), 0, "terminal failure rejects further gameplay input")

	var finish_pending = GameplaySessionScript.new()
	finish_pending.start(_chart([_tap("tap", 1000, 1)]))
	var pending_result: Dictionary = finish_pending.finish_song(1000)
	runner.expect_equal(pending_result.counts.MISS, 1, "song end resolves an already-due unhit note as MISS")
	runner.expect_equal(pending_result.status, GameplaySessionScript.SUCCESS, "nonfatal song-end MISS still succeeds")

	var retry = GameplaySessionScript.new()
	retry.start(_chart([_hold("hold", 100, 3, 300, [200])]))
	retry.press_pad(3, 100)
	retry.advance_to(200)
	runner.expect_equal(retry.score_tracker.judgment_count, 2, "first attempt accumulates initial and Hold tick")
	runner.expect(retry.note_controller.is_pad_held(3), "first attempt has active held input")
	retry.retry()
	runner.expect_equal(retry.status, GameplaySessionScript.RUNNING, "retry begins a running session")
	runner.expect_equal(retry.score_tracker.score, 0, "retry clears score")
	runner.expect_equal(retry.score_tracker.combo, 0, "retry clears combo")
	runner.expect_equal(retry.score_tracker.judgment_count, 0, "retry clears judgment statistics")
	runner.expect_equal(retry.score_tracker.max_combo, 0, "retry clears maximum combo")
	runner.expect_equal(retry.score_tracker.miss_streak, 0, "retry clears MISS streak")
	runner.expect(not retry.note_controller.is_pad_held(3), "retry clears held input state")
	runner.expect(not retry.note_controller.get_note_state("hold").initial_judged, "retry restores note lifecycle")
	retry.reset()
	runner.expect_equal(retry.status, GameplaySessionScript.IDLE, "session reset returns to idle")
	runner.expect_equal(retry.score_tracker.judgment_count, 0, "session reset leaves no result statistics")

	var gameplay_scene := load("res://scenes/gameplay/gameplay.tscn") as PackedScene
	var gameplay = gameplay_scene.instantiate()
	runner.root.add_child(gameplay)
	gameplay.begin_session(_chart([_tap("tap", 100, 7)]))
	var key_press := InputEventKey.new()
	key_press.physical_keycode = KEY_Q
	key_press.pressed = true
	runner.expect(gameplay.pad_grid.handle_key_event(key_press), "gameplay scene accepts routed keyboard input")
	runner.expect_equal(gameplay.session.score_tracker.judgment_count, 1, "gameplay scene routes pad press into session")
	gameplay.retry_session()
	runner.expect(not gameplay.session.note_controller.is_pad_held(7), "scene retry clears session-held pad state")
	runner.expect(gameplay.pad_grid.handle_key_event(key_press), "scene retry clears physical input source state")
	runner.expect_equal(gameplay.session.score_tracker.judgment_count, 1, "clean retry accepts same physical key as a new press")
	gameplay.stop_session()
	runner.expect_equal(gameplay.session.status, GameplaySessionScript.IDLE, "gameplay scene stop discards unfinished session")
	gameplay.free()


func _tracker_with_counts(perfect: int, great: int, good: int, bad: int, miss: int):
	var tracker = ScoreTrackerScript.new()
	for index in range(perfect):
		tracker.apply_judgment("PERFECT")
	for index in range(great):
		tracker.apply_judgment("GREAT")
	for index in range(good):
		tracker.apply_judgment("GOOD")
	for index in range(bad):
		tracker.apply_judgment("BAD")
	for index in range(miss):
		tracker.apply_judgment("MISS")
	return tracker


func _chart(notes: Array) -> Dictionary:
	return {
		"version": 1,
		"song_id": "m3-test",
		"difficulty": "test",
		"notes": notes,
	}


func _tap(id: String, time_ms: int, pad: int) -> Dictionary:
	return {"id": id, "time_ms": time_ms, "pad": pad, "type": "tap"}


func _hold(id: String, time_ms: int, pad: int, end_ms: int, ticks_ms: Array) -> Dictionary:
	return {
		"id": id,
		"time_ms": time_ms,
		"pad": pad,
		"type": "hold",
		"end_ms": end_ms,
		"ticks_ms": ticks_ms,
	}


func _tap_sequence(count: int) -> Array:
	var notes := []
	for index in range(count):
		notes.append(_tap("tap-%d" % index, index * 100, (index % 9) + 1))
	return notes
