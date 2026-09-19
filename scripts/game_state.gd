extends Node

## Runtime-only cosmetic selections. Save-v1 intentionally does not persist them.
var selected_character_id := ""
var selected_table_id := ""


func set_selected_character(id: String) -> void:
	selected_character_id = id


func set_selected_table(id: String) -> void:
	selected_table_id = id


func clear_cosmetic_selection() -> void:
	selected_character_id = ""
	selected_table_id = ""
