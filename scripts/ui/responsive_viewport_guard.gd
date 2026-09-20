class_name ResponsiveViewportGuard
extends CanvasLayer

signal blocking_changed(blocking: bool)

var _overlay: Control
var _blocking := false
var _test_window_size := Vector2i.ZERO
var _test_mobile: Variant = null


func _ready() -> void:
	layer = 100
	_build_overlay()
	get_tree().root.size_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if get_tree() != null and get_tree().root.size_changed.is_connected(_refresh):
		get_tree().root.size_changed.disconnect(_refresh)


func is_blocking() -> bool:
	return _blocking


func set_environment_for_testing(window_size: Vector2i, mobile: bool) -> void:
	_test_window_size = window_size
	_test_mobile = mobile
	_refresh()


static func should_block_for_orientation(window_size: Vector2i, mobile: bool) -> bool:
	return mobile and window_size.x > window_size.y


func _refresh() -> void:
	if _overlay == null:
		return
	var window_size := _test_window_size if _test_window_size != Vector2i.ZERO else DisplayServer.window_get_size()
	var mobile := bool(_test_mobile) if _test_mobile != null else (
		OS.has_feature("mobile")
		or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
	)
	var next_blocking := should_block_for_orientation(window_size, mobile)
	_overlay.visible = next_blocking
	if next_blocking == _blocking:
		return
	_blocking = next_blocking
	blocking_changed.emit(_blocking)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "RotateDeviceOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var background := ColorRect.new()
	background.color = Color("090d18")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(background)

	var message := Label.new()
	message.name = "Message"
	message.text = "GIRE O DISPOSITIVO\nPARA O MODO RETRATO"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 32)
	message.anchor_left = 0.12
	message.anchor_top = 0.32
	message.anchor_right = 0.88
	message.anchor_bottom = 0.68
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(message)
