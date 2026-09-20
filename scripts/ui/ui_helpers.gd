class_name UiHelpers
extends RefCounted

static func panel(color: Color = Color("172033")) -> ColorRect:
	var value := ColorRect.new()
	value.color = color
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return value


static func label(text: String, font_size: int = 28, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var value := Label.new()
	value.text = text
	value.horizontal_alignment = alignment
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", font_size)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return value


static func button(text: String, font_size: int = 24) -> Button:
	var value := Button.new()
	value.text = text
	value.add_theme_font_size_override("font_size", font_size)
	value.focus_mode = Control.FOCUS_ALL
	value.custom_minimum_size = Vector2(72.0, 56.0)
	return value


static func anchor(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


static func attach_viewport_guard(parent: Control) -> ResponsiveViewportGuard:
	var guard := ResponsiveViewportGuard.new()
	guard.name = "ResponsiveViewportGuard"
	parent.add_child(guard)
	return guard


static func title_scroll_offset(text_width: float, viewport_width: float, elapsed_seconds: float) -> float:
	var overflow := maxf(0.0, text_width - viewport_width)
	if overflow <= 0.0:
		return 0.0
	var travel_seconds := overflow / 32.0
	var cycle_seconds := 1.0 + travel_seconds + 1.0
	var phase := fposmod(elapsed_seconds, cycle_seconds)
	return clampf((phase - 1.0) * 32.0, 0.0, overflow)
