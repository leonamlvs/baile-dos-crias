class_name StartScreen
extends Control

const UiHelpersScript = preload("res://scripts/ui/ui_helpers.gd")
const PresentationSlotScript = preload("res://scripts/ui/presentation_slot.gd")
const WebBackupAdapterScript = preload("res://scripts/save/web_backup_adapter.gd")

const START_MUSIC_PATH := "res://assets/ref/audio/BASE DE FUNK 150 BPM  INSTRUMENTAL  USO LIVRE 03 Prod DIL34N.mp3"
const START_BPM := 150.0

var _start_button: Button
var _left_speaker: Control
var _right_speaker: Control
var _wave: Control
var _started := false
var _data_modal: Control
var _data_status: Label
var _data_menu: VBoxContainer
var _confirmation_row: HBoxContainer
var _pending_import_token := ""
var _backup_adapter = WebBackupAdapterScript.new()

@export var beat_offset_ms := 0
@export var enable_start_music := true
@export_file var background_visual := ""
@export_file var logo_visual := ""
@export_file var left_speaker_visual := ""
@export_file var right_speaker_visual := ""
@export_file var soundwave_visual := ""


func _ready() -> void:
	_build()
	UiHelpersScript.attach_viewport_guard(self)
	_backup_adapter.import_text_received.connect(_on_import_text_received)
	_backup_adapter.import_request_failed.connect(_show_data_error)
	AudioManager.stop_preview()
	AudioManager.stop_gameplay()
	if enable_start_music:
		var start_stream := load(START_MUSIC_PATH) as AudioStream
		if start_stream != null:
			AudioManager.start_start_music(start_stream)


func _exit_tree() -> void:
	AudioManager.stop_start_music()


func _process(_delta: float) -> void:
	var phase := AudioManager.get_start_beat_phase(START_BPM, beat_offset_ms)
	var pulse := 1.0 + 0.12 * (1.0 - phase)
	_left_speaker.pivot_offset = _left_speaker.size * 0.5
	_right_speaker.pivot_offset = _right_speaker.size * 0.5
	_wave.pivot_offset = _wave.size * 0.5
	_left_speaker.scale = Vector2(pulse, pulse)
	_right_speaker.scale = Vector2(pulse, pulse)
	_wave.modulate.a = 1.0 - phase
	_wave.scale = Vector2(0.35 + phase * 1.5, 0.35 + phase * 1.5)
	_start_button.position.y = size.y * 0.74 + sin(float(Time.get_ticks_msec()) / 450.0) * 8.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		_begin()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var background := PresentationSlotScript.new("BackgroundSlot", Color("10182b"))
	background.configure_path(background_visual, "")
	UiHelpersScript.anchor(background, 0.0, 0.0, 1.0, 1.0)
	add_child(background)

	var logo := PresentationSlotScript.new("LogoSlot", Color("182845"))
	logo.configure_path(logo_visual, "BAILE DOS CRIAS")
	UiHelpersScript.anchor(logo, 0.08, 0.08, 0.92, 0.22)
	add_child(logo)

	_left_speaker = PresentationSlotScript.new("LeftSpeakerSlot", Color("395b86"))
	_left_speaker.configure_path(left_speaker_visual, "")
	UiHelpersScript.anchor(_left_speaker, 0.10, 0.34, 0.36, 0.55)
	add_child(_left_speaker)
	_right_speaker = PresentationSlotScript.new("RightSpeakerSlot", Color("395b86"))
	_right_speaker.configure_path(right_speaker_visual, "")
	UiHelpersScript.anchor(_right_speaker, 0.64, 0.34, 0.90, 0.55)
	add_child(_right_speaker)
	_wave = PresentationSlotScript.new("SoundwaveSlot", Color("7dd3fc", 0.6))
	_wave.configure_path(soundwave_visual, "")
	UiHelpersScript.anchor(_wave, 0.36, 0.34, 0.64, 0.55)
	add_child(_wave)

	_start_button = UiHelpersScript.button("VAI", 38)
	UiHelpersScript.anchor(_start_button, 0.30, 0.74, 0.70, 0.84)
	_start_button.pressed.connect(_begin)
	add_child(_start_button)

	var hint := UiHelpersScript.label("SPACE / ENTER", 18)
	UiHelpersScript.anchor(hint, 0.25, 0.87, 0.75, 0.92)
	add_child(hint)

	var data_button := UiHelpersScript.button("DATA", 16)
	data_button.name = "DataButton"
	UiHelpersScript.anchor(data_button, 0.40, 0.93, 0.60, 0.985)
	data_button.pressed.connect(open_data_modal)
	add_child(data_button)

	_build_data_modal()


func _begin() -> void:
	if _started:
		return
	_started = true
	AudioManager.stop_start_music()
	get_node("/root/ScreenRouter").go_to_character_select()


func open_data_modal() -> void:
	_set_data_primary_state("")
	_data_modal.visible = true


func close_data_modal() -> void:
	_cancel_pending_import()
	_data_modal.visible = false


func _export_data() -> void:
	var exported: Dictionary = SaveManager.export_json()
	var result: Dictionary = _backup_adapter.download_json(exported.filename, exported.json)
	if result.ok:
		_data_status.text = "Backup exportado."
	else:
		_show_data_error(result.error)


func _request_import() -> void:
	_cancel_pending_import()
	var result: Dictionary = _backup_adapter.request_import_file()
	if result.ok:
		_data_status.text = "Selecione um arquivo JSON."
	else:
		_show_data_error(result.error)


func _on_import_text_received(text: String) -> void:
	_cancel_pending_import()
	var prepared: Dictionary = SaveManager.prepare_import(text)
	if not prepared.ok:
		_show_data_error("Backup rejeitado: %s" % prepared.error)
		return
	_pending_import_token = String(prepared.token)
	_data_status.text = "Backup válido. Substituir os dados locais?"
	_data_menu.visible = false
	_confirmation_row.visible = true


func _confirm_import() -> void:
	if _pending_import_token.is_empty():
		_show_data_error("Nenhum backup validado aguarda confirmação.")
		return
	var result: Dictionary = SaveManager.confirm_import(_pending_import_token)
	if not result.ok:
		_show_data_error("Não foi possível substituir os dados: %s" % result.error)
		return
	_pending_import_token = ""
	AudioManager.set_master_volume(SaveManager.get_master_volume())
	_set_data_primary_state("Dados substituídos e salvos.")


func _cancel_import() -> void:
	_cancel_pending_import()
	_set_data_primary_state("Importação cancelada; os dados atuais foram mantidos.")


func _cancel_pending_import() -> void:
	if not _pending_import_token.is_empty():
		SaveManager.cancel_import(_pending_import_token)
	_pending_import_token = ""


func _show_data_error(message: String) -> void:
	_cancel_pending_import()
	_set_data_primary_state(message)


func _set_data_primary_state(message: String) -> void:
	_data_status.text = message
	_data_menu.visible = true
	_confirmation_row.visible = false


func _build_data_modal() -> void:
	_data_modal = UiHelpersScript.panel(Color("050810", 0.72))
	_data_modal.name = "DataModal"
	UiHelpersScript.anchor(_data_modal, 0.0, 0.0, 1.0, 1.0)
	_data_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_data_modal)
	var dialog := UiHelpersScript.panel(Color("0b1020", 0.98))
	dialog.name = "Dialog"
	UiHelpersScript.anchor(dialog, 0.13, 0.27, 0.87, 0.73)
	_data_modal.add_child(dialog)

	var title := UiHelpersScript.label("DATA", 32)
	UiHelpersScript.anchor(title, 0.12, 0.05, 0.88, 0.20)
	dialog.add_child(title)
	_data_status = UiHelpersScript.label("", 17)
	_data_status.name = "DataStatus"
	UiHelpersScript.anchor(_data_status, 0.10, 0.20, 0.90, 0.36)
	dialog.add_child(_data_status)

	_data_menu = VBoxContainer.new()
	_data_menu.name = "DataMenu"
	_data_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_data_menu.add_theme_constant_override("separation", 12)
	UiHelpersScript.anchor(_data_menu, 0.18, 0.38, 0.82, 0.93)
	dialog.add_child(_data_menu)
	var export_button := UiHelpersScript.button("EXPORT DATA", 19)
	export_button.pressed.connect(_export_data)
	_data_menu.add_child(export_button)
	var import_button := UiHelpersScript.button("IMPORT DATA", 19)
	import_button.pressed.connect(_request_import)
	_data_menu.add_child(import_button)
	var close_button := UiHelpersScript.button("CLOSE", 19)
	close_button.pressed.connect(close_data_modal)
	_data_menu.add_child(close_button)

	_confirmation_row = HBoxContainer.new()
	_confirmation_row.name = "ImportConfirmation"
	_confirmation_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirmation_row.add_theme_constant_override("separation", 18)
	UiHelpersScript.anchor(_confirmation_row, 0.12, 0.55, 0.88, 0.75)
	dialog.add_child(_confirmation_row)
	var replace_button := UiHelpersScript.button("REPLACE", 19)
	replace_button.name = "ReplaceButton"
	replace_button.pressed.connect(_confirm_import)
	_confirmation_row.add_child(replace_button)
	var cancel_button := UiHelpersScript.button("CANCEL", 19)
	cancel_button.name = "CancelButton"
	cancel_button.pressed.connect(_cancel_import)
	_confirmation_row.add_child(cancel_button)

	_data_modal.visible = false
	_confirmation_row.visible = false
