extends Node

## Runtime-only cosmetic selections. Save-v1 intentionally does not persist them.
var selected_character_id := ""
var selected_table_id := ""
var selected_song_id := ""
var selected_difficulty := ""
var last_result := {}
var last_new_record := false


func set_selected_character(id: String) -> void:
	selected_character_id = id


func set_selected_table(id: String) -> void:
	selected_table_id = id


func clear_cosmetic_selection() -> void:
	selected_character_id = ""
	selected_table_id = ""


func set_selected_song(id: String, difficulty: String) -> void:
	selected_song_id = id
	selected_difficulty = difficulty


func set_result(result: Dictionary, new_record: bool) -> void:
	last_result = result.duplicate(true)
	last_new_record = new_record


func clear_session_context() -> void:
	selected_song_id = ""
	selected_difficulty = ""
	last_result.clear()
	last_new_record = false
