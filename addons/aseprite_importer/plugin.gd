@tool
extends EditorPlugin


const INTERFACE_SCN = preload("interface/Main.tscn")
const DARK_ICON = preload("interface/icons/dark_icon.png")
const LIGHT_ICON = preload("interface/icons/light_icon.png")

var interface : Control

var editor_interface := get_editor_interface()
var editor_base_control := editor_interface.get_base_control()
var editor_settings := editor_interface.get_editor_settings()
var editor_viewport := editor_interface.get_editor_main_screen()


var _state_set := false


func _enter_tree() -> void:
	interface = INTERFACE_SCN.instantiate()

	interface.ready.connect(_on_interface_ready, 4) #idk why but it doesn't recognise CONNECT_ONESHOT

	editor_viewport.add_child(interface)
	_make_visible(false)

	scene_changed.connect(_on_scene_changed)
	editor_settings.settings_changed.connect(_on_settings_changed)
	interface.animations_generated.connect(_on_animations_generated)
	


func _exit_tree() -> void:
	if interface:
		interface.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible: bool) -> void:
	if interface:
		if visible:
			interface.show()
		else:
			interface.hide()


func _get_plugin_name():
	return "Aseprite Importer"


func _get_plugin_icon():
	var editor_theme := editor_base_control.theme

	if editor_theme.get_constant("dark_theme", "Editor"):
		return LIGHT_ICON;

	return DARK_ICON;


func get_state() -> Dictionary:
	return interface.get_state()


func set_state(state: Dictionary) -> void:
	interface.set_state(state)

	_state_set = true


func _update_theme() -> void:
	var editor_theme := EditorTheme.new(editor_base_control.theme)
	interface.propagate_call("_update_theme", [editor_theme])


# Signal Callbacks
func _on_animations_generated(animation_player : AnimationPlayer) -> void:
	var editor_selection := get_editor_interface().get_selection()

	editor_selection.clear()
	# Reselect the AnimationPlayer node to show the new animations
	editor_selection.add_node(animation_player)


func _on_interface_ready() -> void:
	_update_theme()


func _on_scene_changed(scene_root : Node) -> void:
	if _state_set == false:
		interface.set_state({})
	_state_set = false


func _on_settings_changed() -> void:
	await editor_base_control.draw

	_update_theme()
