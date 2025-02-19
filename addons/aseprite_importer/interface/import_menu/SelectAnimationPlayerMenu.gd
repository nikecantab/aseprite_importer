@tool
extends Container


@onready var select_button : Button = $Button
@onready var select_node_dialog : Window = $SelectNodeDialog


const SELECT_BUTTON_DEFAULT_TEXT := "Select a Node"


var animation_player : AnimationPlayer : set = set_animation_player


signal node_selected(animation_player)


func _ready():
	select_node_dialog.class_filters = ["AnimationPlayer"]

	select_button.pressed.connect(_on_SelectButton_pressed)
	select_node_dialog.node_selected.connect(_on_SelectNodeDialog_node_selected)


func get_state() -> Dictionary:
	var state := {}

	if animation_player:
		state.animation_player = animation_player

	return state


func set_state(new_state : Dictionary) -> void:
	var new_animation_player : Node = new_state.get("animation_player")

	if new_animation_player != null :
		self.animation_player = new_animation_player
	else:
		animation_player = null
		select_button.text = SELECT_BUTTON_DEFAULT_TEXT


func _update_theme(editor_theme : EditorTheme) -> void:
	select_button.icon = editor_theme.get_icon("AnimationPlayer")


# Setters and Getters
#Notes on Godot 4 conversion: check if function is called elsewhere by name
#if not, it might be better to paste the code in the setter declaration above
func set_animation_player(node : AnimationPlayer) -> void:
	animation_player = node

	if node != null:
		var node_path := node.owner.get_parent().get_path_to(node)
		select_button.text = node_path


# Signal Callbacks
func _on_SelectButton_pressed() -> void:
	if select_node_dialog.initialize():
		select_node_dialog.popup_centered_ratio(.5)


func _on_SelectNodeDialog_node_selected(selected_node : Node) -> void:
	self.animation_player = selected_node
	emit_signal("node_selected", selected_node)
