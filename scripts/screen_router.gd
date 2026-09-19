extends Node

signal route_requested(route: String, scene_path: String)

const ROUTES := {
	"start": "res://scenes/start/start.tscn",
	"character_select": "res://scenes/character_select/character_select.tscn",
	"song_select": "res://scenes/song_select/song_select.tscn",
	"gameplay": "res://scenes/gameplay/gameplay.tscn",
	"results": "res://scenes/results/results.tscn",
}

var last_error := ""
var _navigation_handler := Callable()


func go_to(route: String) -> bool:
	if not ROUTES.has(route):
		last_error = "Unknown screen route '%s'." % route
		return false
	var scene_path: String = ROUTES[route]
	last_error = ""
	route_requested.emit(route, scene_path)
	if _navigation_handler.is_valid():
		_navigation_handler.call(route, scene_path)
		return true
	return get_tree().change_scene_to_file(scene_path) == OK


func go_to_start() -> bool:
	return go_to("start")


func go_to_character_select() -> bool:
	return go_to("character_select")


func go_to_song_select() -> bool:
	return go_to("song_select")


func go_to_gameplay() -> bool:
	return go_to("gameplay")


func go_to_results() -> bool:
	return go_to("results")


func set_navigation_handler_for_testing(handler: Callable) -> void:
	_navigation_handler = handler
