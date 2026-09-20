class_name ResultsScreen
extends Control

const UiHelpersScript = preload("res://scripts/ui/ui_helpers.gd")

var _new_record_label: Label


func _ready() -> void:
	AudioManager.stop_start_music()
	AudioManager.stop_preview()
	_build()
	UiHelpersScript.attach_viewport_guard(self)


func _process(_delta: float) -> void:
	if is_instance_valid(_new_record_label) and _new_record_label.visible:
		var pulse := 1.0 + 0.08 * sin(float(Time.get_ticks_msec()) / 120.0)
		_new_record_label.scale = Vector2(pulse, pulse)


func _build() -> void:
	var background := UiHelpersScript.panel(Color("17203a"))
	UiHelpersScript.anchor(background, 0.0, 0.0, 1.0, 1.0)
	add_child(background)
	var result: Dictionary = GameState.last_result
	var title := UiHelpersScript.label("RESULTADO", 38)
	UiHelpersScript.anchor(title, 0.15, 0.06, 0.85, 0.14)
	add_child(title)
	var rank := UiHelpersScript.label(String(result.get("rank", "F")), 108)
	UiHelpersScript.anchor(rank, 0.30, 0.16, 0.70, 0.34)
	add_child(rank)
	var presentation := UiHelpersScript.label(
		"%s + %s" % [
			GameState.selected_character_id if not GameState.selected_character_id.is_empty() else "PERSONAGEM",
			GameState.selected_table_id if not GameState.selected_table_id.is_empty() else "MESA DJ",
		],
		20,
	)
	UiHelpersScript.anchor(presentation, 0.12, 0.33, 0.88, 0.37)
	add_child(presentation)
	var score := UiHelpersScript.label("SCORE %d\nMAX COMBO %d" % [int(result.get("score", 0)), int(result.get("max_combo", 0))], 28)
	UiHelpersScript.anchor(score, 0.14, 0.38, 0.86, 0.48)
	add_child(score)
	var counts: Dictionary = result.get("counts", {})
	var statistics := UiHelpersScript.label(
		"PERFECT %d   GREAT %d   GOOD %d\nBAD %d   MISS %d\nACCURACY %.2f%%" % [
			int(counts.get("PERFECT", 0)), int(counts.get("GREAT", 0)), int(counts.get("GOOD", 0)),
			int(counts.get("BAD", 0)), int(counts.get("MISS", 0)), float(result.get("accuracy", 0.0)),
		],
		22,
	)
	UiHelpersScript.anchor(statistics, 0.10, 0.52, 0.90, 0.68)
	add_child(statistics)
	_new_record_label = UiHelpersScript.label("NEW RECORD", 30)
	UiHelpersScript.anchor(_new_record_label, 0.18, 0.72, 0.82, 0.79)
	_new_record_label.visible = GameState.last_new_record
	_new_record_label.modulate = Color("facc15")
	add_child(_new_record_label)
	var retry := UiHelpersScript.button("RETRY")
	UiHelpersScript.anchor(retry, 0.06, 0.90, 0.31, 0.97)
	retry.pressed.connect(func() -> void: get_node("/root/ScreenRouter").go_to_gameplay())
	add_child(retry)
	var exit := UiHelpersScript.button("SAIR")
	UiHelpersScript.anchor(exit, 0.69, 0.90, 0.94, 0.97)
	exit.pressed.connect(func() -> void: get_node("/root/ScreenRouter").go_to_song_select())
	add_child(exit)
