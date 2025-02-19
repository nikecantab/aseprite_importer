@tool
extends Container


@onready var h_scroll_bar : HScrollBar = $HScrollBar
@onready var v_scroll_bar : VScrollBar = $VScrollBar


@export var texture : Texture2D : set = set_texture
@export_range(1, 8) var zoom : int = 1 : set = set_zoom
#renamed to avoid conflicts with godot 4.0's set_offset V
@export var pos_offset : Vector2 = Vector2.ZERO : set = set_pos_offset
@export var zoom_to_fit : bool = true


var frames = []
var selected_frames := [] : set = set_selected_frames

var frame_border_color := Color.RED
var frame_border_visibility := true

var selection_border_color := Color.YELLOW
var selection_border_visibility := true

var border_width := 2

var texture_background_color := Color.GREEN
var texture_background_visibility := true

var background_color := Color.BLUE

var _full_rect := Rect2(Vector2.ZERO, size)
var _render_rect : Rect2
var _texture_size : Vector2
var _min_offset : Vector2
var _max_offset : Vector2
var _zoom_pivot : Vector2

var _updating_scroll_bars := false
var _panning := false


signal zoom_changed(new_zoom)


func _ready() -> void:
	h_scroll_bar.value = .5
	v_scroll_bar.value = .5

	resized.connect(_on_resized)
	h_scroll_bar.value_changed.connect(_on_HScrollBar_value_changed)
	v_scroll_bar.value_changed.connect(_on_VScrollBar_value_changed)

	queue_redraw()


func _draw() -> void:
	draw_rect(_full_rect, background_color)

	if not texture:
		return

	if texture_background_visibility:
		draw_rect(_render_rect, texture_background_color)

	draw_texture_rect(texture, _render_rect, false)

	if frame_border_visibility:
		for frame_idx in range(frames.size()):
			if (not selection_border_visibility) or (not frame_idx in selected_frames):
				_draw_frame_border(frame_idx)

	if selection_border_visibility:
		for frame_idx in selected_frames:
			_draw_frame_border(frame_idx, true)


func _draw_frame_border(frame_idx : int, selected := false) -> void:
	var sprite_region = frames[frame_idx].frame

	var frame_rect := _render_rect
	frame_rect.position += Vector2(sprite_region.x, sprite_region.y) * zoom
	frame_rect.size = Vector2(sprite_region.w, sprite_region.h) * zoom

	var border_color

	if frame_idx in selected_frames:
		border_color = selection_border_color
	else:
		border_color = frame_border_color

	draw_rect(frame_rect, border_color, false, border_width)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				_panning = event.pressed

				if _panning:
					mouse_default_cursor_shape = CURSOR_DRAG
				else:
					mouse_default_cursor_shape = CURSOR_ARROW
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_pivot = get_local_mouse_position()

					if event.button_index == MOUSE_BUTTON_WHEEL_UP:
						self.zoom += 1
					else:
						self.zoom -= 1

					_zoom_pivot = _full_rect.size / 2
	elif event is InputEventMouseMotion:
		if _panning:
			self.pos_offset += event.relative


func load_settings(settings : Dictionary) -> void:
	frame_border_color = settings.frame_border.color
	frame_border_visibility = settings.frame_border.visibility

	selection_border_color = settings.selection_border.color
	selection_border_visibility = settings.selection_border.visibility

	texture_background_color = settings.texture_background.color
	texture_background_visibility = settings.texture_background.visibility

	background_color = settings.inspector_background.color

	queue_redraw()


func _update_offset_limits() -> void:
	var full_rect_width := _full_rect.size.x
	var render_rect_width := _render_rect.size.x

	if render_rect_width <= full_rect_width:
		_min_offset.x = 0
		_max_offset.x = full_rect_width - render_rect_width
	else:
		_min_offset.x = -(render_rect_width - full_rect_width)
		_max_offset.x = 0

	var full_rect_height := _full_rect.size.y
	var render_rect_height := _render_rect.size.y

	if render_rect_height <= full_rect_height:
		_min_offset.y = 0
		_max_offset.y = full_rect_height - render_rect_height
	else:
		_min_offset.y = -(render_rect_height - full_rect_height)
		_max_offset.y = 0


func _update_scrollbars() ->void:
	_updating_scroll_bars = true

	if h_scroll_bar:
		var full_width:= _full_rect.size.x
		var render_width:= _render_rect.size.x

		if render_width > full_width:
			var h_page := full_width / render_width

			h_scroll_bar.page = h_page
			h_scroll_bar.max_value = 1 + h_page

			var value := inverse_lerp(_max_offset.x, _min_offset.x, pos_offset.x)
			h_scroll_bar.value = value

			h_scroll_bar.show()
		else:
			h_scroll_bar.hide()

	if v_scroll_bar:
		var full_height:= _full_rect.size.y
		var render_height:= _render_rect.size.y

		if render_height > full_height:
			var v_page := full_height / render_height

			v_scroll_bar.page = v_page
			v_scroll_bar.max_value = 1 + v_page

			var value := inverse_lerp(_max_offset.y, _min_offset.y, pos_offset.y)
			v_scroll_bar.value = value

			v_scroll_bar.show()
		else:
			v_scroll_bar.hide()

	_updating_scroll_bars = false


# Setters and Getters
func set_pos_offset(new_offset : Vector2) -> void:
	new_offset.x = clamp(new_offset.x, _min_offset.x, _max_offset.x)
	new_offset.y = clamp(new_offset.y, _min_offset.y, _max_offset.y)

	if new_offset == pos_offset:
		return

	pos_offset = new_offset

	_render_rect.position = pos_offset

	if not _updating_scroll_bars:
		_update_scrollbars()

	queue_redraw()


func set_selected_frames(selection : Array) -> void:
	selected_frames = selection

	queue_redraw()


func set_texture(new_texture) -> void:
	texture = new_texture

	if texture == null:
		return

	_texture_size = texture.get_size()
	var full_rect_size := _full_rect.size

	if zoom_to_fit:
		var ratio : Vector2

		ratio.x = floor(full_rect_size.x / _texture_size.x)
		ratio.y = floor(full_rect_size.y / _texture_size.y)

		self.zoom = min(ratio.x, ratio.y)
	else:
		self.zoom = 1

	_update_offset_limits()

	self.pos_offset = (_max_offset - _min_offset) / 2


func set_zoom(new_zoom : int) -> void:
	zoom = clamp(new_zoom, 1, 8)

	var new_render_rect_size := _texture_size * zoom
	var relative_pivot := _zoom_pivot - pos_offset

	var pivot_weight : Vector2

	if _render_rect.size.x and _render_rect.size.y:
		pivot_weight.x = relative_pivot.x / _render_rect.size.x
		pivot_weight.y = relative_pivot.y / _render_rect.size.y

	var render_rect_size_diff := new_render_rect_size - _render_rect.size
	var offset_diff := render_rect_size_diff * pivot_weight

	_render_rect.size = new_render_rect_size

	_update_offset_limits()

	_update_scrollbars()

	self.pos_offset = pos_offset - offset_diff

	emit_signal("zoom_changed", zoom)


# Signal Callbacks
func _on_resized() -> void:
	_full_rect.size = size

	_zoom_pivot = _full_rect.size / 2

	_update_offset_limits()

	_update_scrollbars()

	self.pos_offset = pos_offset

	var rect := Rect2()

	rect.position.x = 0
	rect.position.y = (size.y - h_scroll_bar.size.y)
	rect.size.x = (size.x - v_scroll_bar.size.x)
	rect.size.y = h_scroll_bar.size.y

	fit_child_in_rect(h_scroll_bar, rect)

	rect.position.x = (size.x - v_scroll_bar.size.x)
	rect.position.y = 0
	rect.size.x = v_scroll_bar.size.x
	rect.size.y = (size.y - h_scroll_bar.size.y)

	fit_child_in_rect(v_scroll_bar, rect)



func _on_HScrollBar_value_changed(value : float) -> void:
	if _updating_scroll_bars:
		return

	_updating_scroll_bars = true
	self.pos_offset.x = lerp(_max_offset.x, _min_offset.x, value)
	_updating_scroll_bars = false


func _on_VScrollBar_value_changed(value : float) -> void:
	if _updating_scroll_bars:
		return

	_updating_scroll_bars = true
	self.pos_offset.y = lerp(_max_offset.y, _min_offset.y, value)
	_updating_scroll_bars = false
