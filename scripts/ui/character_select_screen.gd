class_name CharacterSelectScreen
extends Control

const CatalogSelectionScript = preload("res://scripts/ui/catalog_selection.gd")
const ContentCatalogScript = preload("res://scripts/data/content_catalog.gd")
const UiHelpersScript = preload("res://scripts/ui/ui_helpers.gd")
const PresentationSlotScript = preload("res://scripts/ui/presentation_slot.gd")

var character_selection = CatalogSelectionScript.new()
var table_selection = CatalogSelectionScript.new()
var focused_track := 0

var _character_label: Label
var _table_label: Label
var _focus_label: Label
var _next_button: Button
var _character_slot: PresentationSlot
var _table_slot: PresentationSlot
var _swipe_starts := {}

func _ready() -> void:
	AudioManager.stop_start_music()
	AudioManager.stop_preview()
	var catalog = ContentCatalogScript.new()
	catalog.load_from_root()
	configure(catalog.characters, catalog.tables)
	_build()
	UiHelpersScript.attach_viewport_guard(self)
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

	var preview := UiHelpersScript.panel(Color("12283d"))
	preview.name = "PresentationPreview"
	UiHelpersScript.anchor(preview, 0.12, 0.18, 0.88, 0.48)
	add_child(preview)
	_table_slot = PresentationSlotScript.new("TableSlot", Color("31516f"))
	UiHelpersScript.anchor(_table_slot, 0.08, 0.48, 0.92, 0.92)
	preview.add_child(_table_slot)
	_character_slot = PresentationSlotScript.new("CharacterSlot", Color("4b6680"))
	UiHelpersScript.anchor(_character_slot, 0.28, 0.08, 0.72, 0.72)
	preview.add_child(_character_slot)
	_focus_label = UiHelpersScript.label("", 18)
	UiHelpersScript.anchor(_focus_label, 0.20, 0.20, 0.80, 0.25)
	add_child(_focus_label)
	_character_label = UiHelpersScript.label("", 28)
	UiHelpersScript.anchor(_character_label, 0.12, 0.55, 0.88, 0.64)
	add_child(_character_label)
	_table_label = UiHelpersScript.label("", 28)
	UiHelpersScript.anchor(_table_label, 0.12, 0.68, 0.88, 0.77)
	add_child(_table_label)
	_add_swipe_area(0, 0.15, 0.55, 0.85, 0.64)
	_add_swipe_area(1, 0.15, 0.68, 0.85, 0.77)

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
	_character_slot.configure(
		character_selection.current(),
		"visual",
		_display_name(character_selection.current(), "PERSONAGEM"),
	)
	_table_slot.configure(
		table_selection.current(),
		"visual",
		_display_name(table_selection.current(), "MESA DJ"),
	)
	_focus_label.text = "FOCO: %s — use ↑ ↓ e ← →" % ["PERSONAGEM" if focused_track == 0 else "MESA"]
	_next_button.disabled = not can_continue()


func _continue() -> void:
	if can_continue():
		get_node("/root/ScreenRouter").go_to_song_select()


func _display_name(item: Dictionary, fallback: String) -> String:
	return String(item.get("name", fallback))


func _add_swipe_area(track: int, left: float, top: float, right: float, bottom: float) -> void:
	var area := Control.new()
	area.name = "CharacterSwipeArea" if track == 0 else "TableSwipeArea"
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	UiHelpersScript.anchor(area, left, top, right, bottom)
	area.gui_input.connect(func(event: InputEvent) -> void: _on_swipe_input(event, track, area))
	add_child(area)


func _on_swipe_input(event: InputEvent, track: int, area: Control) -> void:
	var source := ""
	var position := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		source = "touch:%d" % event.index
		position = event.position
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		source = "mouse"
		position = event.position
		pressed = event.pressed
	else:
		return
	if pressed:
		_swipe_starts[source] = {"position": position, "track": track}
		area.accept_event()
		return
	if not _swipe_starts.has(source):
		return
	var start: Dictionary = _swipe_starts[source]
	_swipe_starts.erase(source)
	if int(start.track) != track:
		return
	var direction := CatalogSelectionScript.swipe_direction(position.x - Vector2(start.position).x)
	if direction != 0:
		set_focus_track(track)
		move_focused(direction)
	area.accept_event()
