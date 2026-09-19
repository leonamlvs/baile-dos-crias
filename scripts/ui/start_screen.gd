class_name StartScreen
extends Control

const UiHelpersScript = preload("res://scripts/ui/ui_helpers.gd")

var _start_button: Button
var _left_speaker: ColorRect
var _right_speaker: ColorRect
var _wave: ColorRect
var _started := false


func _ready() -> void:
	_build()
	AudioManager.stop_preview()
	AudioManager.stop_gameplay()


func _process(_delta: float) -> void:
	var phase := fmod(float(Time.get_ticks_msec()) / 400.0, 1.0)
	var pulse := 0.88 + 0.12 * sin(phase * TAU)
	_left_speaker.scale = Vector2(pulse, pulse)
	_right_speaker.scale = Vector2(pulse, pulse)
	_wave.modulate.a = 1.0 - phase
	_wave.scale = Vector2(0.35 + phase * 1.5, 0.35 + phase * 1.5)
	_start_button.position.y = sin(float(Time.get_ticks_msec()) / 450.0) * 8.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		_begin()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var background := UiHelpersScript.panel(Color("10182b"))
	UiHelpersScript.anchor(background, 0.0, 0.0, 1.0, 1.0)
	add_child(background)

	var title := UiHelpersScript.label("BAILE DOS CRIAS", 54)
	UiHelpersScript.anchor(title, 0.08, 0.08, 0.92, 0.22)
	add_child(title)

	_left_speaker = UiHelpersScript.panel(Color("395b86"))
	UiHelpersScript.anchor(_left_speaker, 0.10, 0.34, 0.36, 0.55)
	add_child(_left_speaker)
	_right_speaker = UiHelpersScript.panel(Color("395b86"))
	UiHelpersScript.anchor(_right_speaker, 0.64, 0.34, 0.90, 0.55)
	add_child(_right_speaker)
	_wave = UiHelpersScript.panel(Color("7dd3fc", 0.6))
	UiHelpersScript.anchor(_wave, 0.36, 0.34, 0.64, 0.55)
	add_child(_wave)

	_start_button = UiHelpersScript.button("VAI", 38)
	UiHelpersScript.anchor(_start_button, 0.30, 0.74, 0.70, 0.84)
	_start_button.button_up.connect(_begin)
	add_child(_start_button)

	var hint := UiHelpersScript.label("SPACE / ENTER", 18)
	UiHelpersScript.anchor(hint, 0.25, 0.87, 0.75, 0.92)
	add_child(hint)


func _begin() -> void:
	if _started:
		return
	_started = true
	get_node("/root/ScreenRouter").go_to_character_select()
