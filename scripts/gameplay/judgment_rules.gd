class_name JudgmentRules
extends RefCounted

const PERFECT := "PERFECT"
const GREAT := "GREAT"
const GOOD := "GOOD"
const BAD := "BAD"
const MISS := "MISS"

const MAX_HIT_WINDOW_MS := 220


static func classify(delta_ms: int) -> String:
	var distance_ms := absi(delta_ms)
	if distance_ms <= 50:
		return PERFECT
	if distance_ms <= 100:
		return GREAT
	if distance_ms <= 150:
		return GOOD
	if distance_ms <= MAX_HIT_WINDOW_MS:
		return BAD
	return MISS


static func base_points(judgment: String) -> int:
	match judgment:
		PERFECT:
			return 100
		GREAT:
			return 75
		GOOD:
			return 50
		BAD:
			return 10
		_:
			return 0


static func builds_combo(judgment: String) -> bool:
	return judgment == PERFECT or judgment == GREAT or judgment == GOOD


static func is_valid(judgment: String) -> bool:
	return judgment in [PERFECT, GREAT, GOOD, BAD, MISS]
