class_name ScoreTracker
extends RefCounted

const JudgmentRulesScript = preload("res://scripts/gameplay/judgment_rules.gd")

var score := 0
var combo := 0
var max_combo := 0
var multiplier := 1
var miss_streak := 0
var earned_base_points := 0
var judgment_count := 0
var failed := false
var last_error := ""
var counts := {}


func _init() -> void:
	reset()


func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	multiplier = 1
	miss_streak = 0
	earned_base_points = 0
	judgment_count = 0
	failed = false
	last_error = ""
	counts = {
		JudgmentRulesScript.PERFECT: 0,
		JudgmentRulesScript.GREAT: 0,
		JudgmentRulesScript.GOOD: 0,
		JudgmentRulesScript.BAD: 0,
		JudgmentRulesScript.MISS: 0,
	}


func apply_judgment(judgment: String) -> Dictionary:
	if not JudgmentRulesScript.is_valid(judgment):
		last_error = "Unknown judgment '%s'." % judgment
		return {"ok": false, "error": last_error}

	last_error = ""
	counts[judgment] = int(counts[judgment]) + 1
	judgment_count += 1
	var base_points := JudgmentRulesScript.base_points(judgment)
	earned_base_points += base_points

	if JudgmentRulesScript.builds_combo(judgment):
		combo += 1
		max_combo = maxi(max_combo, combo)
		multiplier = multiplier_for_combo(combo)
	else:
		combo = 0
		multiplier = 1

	var awarded_points := base_points * multiplier
	score += awarded_points

	if judgment == JudgmentRulesScript.MISS:
		miss_streak += 1
		if miss_streak >= 50:
			failed = true
	else:
		miss_streak = 0

	return {
		"ok": true,
		"judgment": judgment,
		"base_points": base_points,
		"awarded_points": awarded_points,
		"score": score,
		"combo": combo,
		"max_combo": max_combo,
		"multiplier": multiplier,
		"miss_streak": miss_streak,
		"failed": failed,
	}


func get_accuracy() -> float:
	if judgment_count == 0:
		return 0.0
	return float(earned_base_points) * 100.0 / float(100 * judgment_count)


func get_rank() -> String:
	var accuracy := get_accuracy()
	if (
		judgment_count > 0
		and accuracy >= 95.0
		and int(counts[JudgmentRulesScript.GOOD]) == 0
		and int(counts[JudgmentRulesScript.BAD]) == 0
		and int(counts[JudgmentRulesScript.MISS]) == 0
	):
		return "S"
	if accuracy >= 90.0:
		return "A"
	if accuracy >= 80.0:
		return "B"
	if accuracy >= 70.0:
		return "C"
	if accuracy >= 60.0:
		return "D"
	return "F"


func snapshot() -> Dictionary:
	return {
		"score": score,
		"combo": combo,
		"max_combo": max_combo,
		"multiplier": multiplier,
		"miss_streak": miss_streak,
		"earned_base_points": earned_base_points,
		"judgment_count": judgment_count,
		"counts": counts.duplicate(true),
		"accuracy": get_accuracy(),
		"rank": get_rank(),
		"failed": failed,
	}


static func multiplier_for_combo(value: int) -> int:
	if value >= 40:
		return 8
	if value >= 30:
		return 6
	if value >= 20:
		return 4
	if value >= 10:
		return 2
	return 1
