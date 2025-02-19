@tool
extends Container


@onready var label : Label = $Header/Label
@onready var visibility_button: Button = $Header/VisibilityButton
@onready var color_picker : ColorPickerButton = $ColorPicker


@export var label_text := '' : set = set_label_text
@export var visibility := true : set = set_visibility
@export var show_visibility_button := true : set = set_show_visibility_button
@export var color_value := Color.BLACK : set = set_color_value
@export var color_edit_alpha := true : set = set_color_edit_alpha
@export_multiline var color_picker_tooltip := "" : set = set_color_picker_tooltip


var _visible_icon : Texture
var _hidden_icon : Texture


signal property_changed(color_menu_item)


func _ready():
	self.label_text = label_text
	self.visibility = visibility
	self.show_visibility_button = show_visibility_button
	self.color_value = color_value
	self.color_edit_alpha = color_edit_alpha
	self.color_picker_tooltip = color_picker_tooltip

	visibility_button.pressed.connect(_on_ViewButton_pressed)
	color_picker.color_changed.connect(_on_ColorPicker_color_changed)


func _update_theme(editor_theme : EditorTheme) -> void:
	_visible_icon = editor_theme.get_icon('GuiVisibilityVisible')
	_hidden_icon = editor_theme.get_icon('GuiVisibilityHidden')

	self.visibility = visibility


# Setters and Getters
func set_color_picker_tooltip(text : String) -> void:
	color_picker_tooltip = text
	if color_picker:
		color_picker.tooltip_text = text


func set_color_value(color: Color) -> void:
	color_value = color
	if color_picker:
		color_picker.color = color_value


func set_color_edit_alpha(value : bool) -> void:
	color_edit_alpha = value
	if color_picker:
		color_picker.edit_alpha = color_edit_alpha


func set_label_text(text : String) -> void:
	label_text = text
	if label:
		label.text = label_text


func set_show_visibility_button(show_button : bool) -> void:
	show_visibility_button = show_button
	if visibility_button:
		visibility_button.visible = show_visibility_button


func set_visibility(value : bool) -> void:
	visibility = value

	if visibility_button:
		if visibility:
			visibility_button.icon = _visible_icon
			visibility_button.modulate.a = 1
		else:
			visibility_button.icon = _hidden_icon
			visibility_button.modulate.a = .5


# Signal Callbacks
func _on_ColorPicker_color_changed(color : Color) -> void:
	color_value = color
	emit_signal('property_changed', self)


func _on_ViewButton_pressed() -> void:
	self.visibility = !visibility
	emit_signal('property_changed', self)
