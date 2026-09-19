class_name CatalogSelection
extends RefCounted

var items: Array[Dictionary] = []
var index := 0


func set_items(value: Array[Dictionary], selected_id: String = "") -> void:
	items = value.duplicate(true)
	index = 0
	if not selected_id.is_empty():
		for item_index in range(items.size()):
			if String(items[item_index].get("id", "")) == selected_id:
				index = item_index
				break


func move(delta: int) -> bool:
	if items.is_empty() or delta == 0:
		return false
	index = posmod(index + delta, items.size())
	return true


func current() -> Dictionary:
	if items.is_empty():
		return {}
	return items[index].duplicate(true)


func current_id() -> String:
	return String(current().get("id", ""))


func has_items() -> bool:
	return not items.is_empty()


class SongSelection:
	extends RefCounted

	var songs := CatalogSelection.new()
	var difficulty := ""

	func set_songs(value: Array[Dictionary], selected_song_id: String = "", selected_difficulty: String = "") -> void:
		songs.set_items(value, selected_song_id)
		difficulty = ""
		if available_difficulties().has(selected_difficulty):
			difficulty = selected_difficulty

	func move_song(delta: int) -> bool:
		var moved := songs.move(delta)
		if moved:
			difficulty = ""
		return moved

	func available_difficulties() -> Array[String]:
		var result: Array[String] = []
		for value in songs.current().get("difficulties", []):
			result.append(String(value))
		return result

	func select_difficulty(id: String) -> bool:
		if not available_difficulties().has(id):
			return false
		difficulty = id
		return true

	func can_continue() -> bool:
		return songs.has_items() and not difficulty.is_empty()
