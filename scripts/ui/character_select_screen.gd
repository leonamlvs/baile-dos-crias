class_name CharacterSelectScreen
extends Control

const CatalogSelectionScript = preload("res://scripts/ui/catalog_selection.gd")
const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const UiHelpersScript = preload("res://scripts/ui/ui_helpers.gd")

var character_selection = CatalogSelectionScript.new()
var table_selection = CatalogSelectionScript.new()
var focused_track := 0

var _character_label: Label
var _table_label: Label
var _focus_label: Label
var _next_button: Button


func _ready() -> void:
	AudioManager.stop_preview()
	var catalog = ContentCatalogScript.new()
	catalog.load_from_root()
	configure(catalog.characters, catalog.tables)
	_build()
	_refresh()


func configure(characters: Array[Dictionary], tables: Array[Dictionary]) -> void:
	character_selection.set_items(characters, GameState.selected_character_id)
	table_selection.set_items(tables, GameState.selected_table_id)
	if character_selection.has_items():
		GameState.set_selected_character(character_selection.current_id())
	if table_selection.has_items():
		GameState.set_selected_table(table_selection.current_id())


func move_focused(delta: int) -> bool:
	var selection = character_selection if focused_track == 0 else table_selection
	var moved: bool = selection.move(delta)
	if moved:
		if focused_track == 0:
			GameState.set_selected_character(character_selection.current_id())
		else:
			GameState.set_selected_table(table_selection.current_id())
		_refresh()
	return moved


func set_focus_track(value: int) -> void:
	focused_track = clampi(value, 0, 1)
	_refresh()


func can_continue() -> bool:
	return character_selection.has_items() and table_selection.has_items()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_UP:
			set_focus_track(0)
		KEY_DOWN:
			set_focus_track(1)
		KEY_LEFT:
			move_focused(-1)
		KEY_RIGHT:
			move_focused(1)
		_:
			return
	get_viewport().set_input_as_handled()


func _build() -> void:
	var background := UiHelpersScript.panel(Color("102137"))
	UiHelpersScript.anchor(background, 0.0, 0.0, 1.0, 1.0)
	add_child(background)
	var title := UiHelpersScript.label("ESCOLHA O DJ E A MESA", 32)
	UiHelpersScript.anchor(title, 0.08, 0.05, 0.92, 0.13)
	add_child(title)
	var back := UiHelpersScript.button("VOLTAR")
	UiHelpersScript.anchor(back, 0.06, 0.90, 0.31, 0.97)
	back.pressed.connect(func() -> void: get_node("/root/ScreenRouter").go_to_start())
	add_child(back)
	_next_button = UiHelpersScript.button("PRÓXIMO")
	UiHelpersScript.anchor(_next_button, 0.69, 0.90, 0.94, 0.97)
	_next_button.pressed.connect(_continue)
	add_child(_next_button)

	var preview := UiHelpersScript.panel(Color("1d3b59"))
	UiHelpersScript.anchor(preview, 0.12, 0.18, 0.88, 0.48)
	add_child(preview)
	_focus_label = UiHelpersScript.label("", 18)
	UiHelpersScript.anchor(_focus_label, 0.20, 0.20, 0.80, 0.25)
	add_child(_focus_label)
	_character_label = UiHelpersScript.label("", 28)
	UiHelpersScript.anchor(_character_label, 0.12, 0.55, 0.88, 0.64)
	add_child(_character_label)
	_table_label = UiHelpersScript.label("", 28)
	UiHelpersScript.anchor(_table_label, 0.12, 0.68, 0.88, 0.77)
	add_child(_table_label)

	var previous_character := UiHelpersScript.button("‹")
	UiHelpersScript.anchor(previous_character, 0.05, 0.55, 0.15, 0.64)
	previous_character.pressed.connect(func() -> void: set_focus_track(0); move_focused(-1))
	add_child(previous_character)
	var next_character := UiHelpersScript.button("›")
	UiHelpersScript.anchor(next_character, 0.85, 0.55, 0.95, 0.64)
	next_character.pressed.connect(func() -> void: set_focus_track(0); move_focused(1))
	add_child(next_character)
	var previous_table := UiHelpersScript.button("‹")
	UiHelpersScript.anchor(previous_table, 0.05, 0.68, 0.15, 0.77)
	previous_table.pressed.connect(func() -> void: set_focus_track(1); move_focused(-1))
	add_child(previous_table)
	var next_table := UiHelpersScript.button("›")
	UiHelpersScript.anchor(next_table, 0.85, 0.68, 0.95, 0.77)
	next_table.pressed.connect(func() -> void: set_focus_track(1); move_focused(1))
	add_child(next_table)


func _refresh() -> void:
	if not is_instance_valid(_character_label):
		return
	_character_label.text = "PERSONAGEM: %s" % _display_name(character_selection.current(), "Nenhum disponível")
	_table_label.text = "MESA: %s" % _display_name(table_selection.current(), "Nenhuma disponível")
	_focus_label.text = "FOCO: %s — use ↑ ↓ e ← →" % ["PERSONAGEM" if focused_track == 0 else "MESA"]
	_next_button.disabled = not can_continue()


func _continue() -> void:
	if can_continue():
		get_node("/root/ScreenRouter").go_to_song_select()


func _display_name(item: Dictionary, fallback: String) -> String:
	return String(item.get("name", fallback))
