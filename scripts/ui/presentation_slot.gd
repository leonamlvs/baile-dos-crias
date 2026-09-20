class_name PresentationSlot
extends Control

var _fallback: ColorRect
var _texture: TextureRect
var _caption: Label


func _init(slot_name: String = "PresentationSlot", fallback_color: Color = Color("1d3b59")) -> void:
	name = slot_name
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback = ColorRect.new()
	_fallback.name = "Fallback"
	_fallback.color = fallback_color
	_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fallback)
	_texture = TextureRect.new()
	_texture.name = "Texture"
	_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture.visible = false
	add_child(_texture)
	_caption = Label.new()
	_caption.name = "Caption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_caption)


func configure(item: Dictionary, asset_field: String, fallback_text: String) -> bool:
	var relative_path := String(item.get(asset_field, ""))
	var resource_path := ""
	if not relative_path.is_empty():
		resource_path = String(item.get("content_path", "")).path_join(relative_path)
	return configure_path(resource_path, fallback_text)


func configure_path(resource_path: String, fallback_text: String) -> bool:
	_caption.text = fallback_text
	_texture.texture = null
	_texture.visible = false
	_fallback.visible = true
	if resource_path.is_empty():
		return false
	var texture := load(resource_path) as Texture2D
	if texture == null:
		return false
	_texture.texture = texture
	_texture.visible = true
	_fallback.visible = false
	_caption.text = ""
	return true


func uses_fallback() -> bool:
	return not _texture.visible
