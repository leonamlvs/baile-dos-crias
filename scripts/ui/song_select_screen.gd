class_name SongSelectScreen
extends Control

const CatalogSelectionScript = preload("res://scripts/ui/catalog_selection.gd")
const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const UiHelpersScript = preload("res://scripts/ui/ui_helpers.gd")

var selection = CatalogSelectionScript.SongSelection.new()
var _song_label: Label
var _details_label: Label
var _difficulty_row: HBoxContainer
var _next_button: Button


func _ready() -> void:
	var catalog = ContentCatalogScript.new()
	catalog.load_from_root()
	configure(catalog.songs)
	_build()
	_refresh()
	_play_selected_preview()


func _exit_tree() -> void:
	AudioManager.stop_preview()


func configure(songs: Array[Dictionary]) -> void:
	selection.set_songs(songs, GameState.selected_song_id, GameState.selected_difficulty)


func move_song(delta: int) -> bool:
	var moved := selection.move_song(delta)
	if moved:
		_play_selected_preview()
		_refresh()
	return moved


func select_difficulty(id: String) -> bool:
	var selected := selection.select_difficulty(id)
	if selected:
		_refresh()
	return selected


func selected_high_score() -> int:
	if selection.difficulty.is_empty():
		return 0
	return SaveManager.get_high_score(selection.songs.current_id(), selection.difficulty)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_UP:
		move_song(-1)
	elif event.keycode == KEY_DOWN:
		move_song(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _build() -> void:
	var background := UiHelpersScript.panel(Color("121d34"))
	UiHelpersScript.anchor(background, 0.0, 0.0, 1.0, 1.0)
	add_child(background)
	var title := UiHelpersScript.label("ESCOLHA A MÚSICA", 32)
	UiHelpersScript.anchor(title, 0.08, 0.05, 0.92, 0.13)
	add_child(title)
	_song_label = UiHelpersScript.label("", 34)
	UiHelpersScript.anchor(_song_label, 0.10, 0.22, 0.90, 0.38)
	add_child(_song_label)
	_details_label = UiHelpersScript.label("", 20)
	UiHelpersScript.anchor(_details_label, 0.12, 0.41, 0.88, 0.55)
	add_child(_details_label)
	_difficulty_row = HBoxContainer.new()
	_difficulty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	UiHelpersScript.anchor(_difficulty_row, 0.10, 0.62, 0.90, 0.70)
	add_child(_difficulty_row)
	var previous := UiHelpersScript.button("▲")
	UiHelpersScript.anchor(previous, 0.43, 0.15, 0.57, 0.21)
	previous.pressed.connect(func() -> void: move_song(-1))
	add_child(previous)
	var next_song := UiHelpersScript.button("▼")
	UiHelpersScript.anchor(next_song, 0.43, 0.72, 0.57, 0.78)
	next_song.pressed.connect(func() -> void: move_song(1))
	add_child(next_song)
	var back := UiHelpersScript.button("VOLTAR")
	UiHelpersScript.anchor(back, 0.06, 0.90, 0.31, 0.97)
	back.pressed.connect(func() -> void: get_node("/root/ScreenRouter").go_to_character_select())
	add_child(back)
	_next_button = UiHelpersScript.button("VAI")
	UiHelpersScript.anchor(_next_button, 0.69, 0.90, 0.94, 0.97)
	_next_button.pressed.connect(_continue)
	add_child(_next_button)


func _refresh() -> void:
	if not is_instance_valid(_song_label):
		return
	var song: Dictionary = selection.songs.current()
	if song.is_empty():
		_song_label.text = "SEM MÚSICAS VÁLIDAS"
		_details_label.text = "Adicione conteúdo validado em content/songs."
	else:
		_song_label.text = "%s\n%s" % [song.title, song.artist]
		_details_label.text = "%s BPM  •  %s  •  HIGH SCORE: %d" % [
			String(song.bpm_display),
			_format_duration(int(song.duration_ms)),
			selected_high_score(),
		]
	for child in _difficulty_row.get_children():
		child.queue_free()
	for difficulty in selection.available_difficulties():
		var choice := UiHelpersScript.button(String(difficulty).to_upper(), 20)
		choice.toggle_mode = true
		choice.button_pressed = String(difficulty) == selection.difficulty
		choice.pressed.connect(func() -> void: select_difficulty(String(difficulty)))
		_difficulty_row.add_child(choice)
	_next_button.disabled = not selection.can_continue()


func _play_selected_preview() -> void:
	AudioManager.stop_preview()
	var song: Dictionary = selection.songs.current()
	if song.is_empty():
		return
	var path := String(song.content_path).path_join(String(song.audio))
	var stream := load(path) as AudioStream
	if stream != null:
		AudioManager.start_preview(stream, int(song.get("preview_start_ms", 0)), 15000, 250)


func _continue() -> void:
	if not selection.can_continue():
		return
	GameState.set_selected_song(selection.songs.current_id(), selection.difficulty)
	AudioManager.stop_preview()
	get_node("/root/ScreenRouter").go_to_gameplay()


func _format_duration(duration_ms: int) -> String:
	var seconds := maxi(0, duration_ms / 1000)
	return "%d:%02d" % [seconds / 60, seconds % 60]
