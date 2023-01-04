@tool
extends Container


@onready var select_all_button : CheckBox = find_child("SelectAllButton")
@onready var options_list : VBoxContainer = find_child("OptionsList")
@onready var color_list : HBoxContainer = find_child("ColorList")
@onready var loopcolor_button : CheckBox = find_child("ColorCodeButton")
@onready var tree : Tree = $Tree


enum Columns {
	SELECTED,
	NAME,
	START,
	END,
	DIRECTION,
	LOOPING
}


var _tree_root : TreeItem
var _options := []
var _toggling_option := false
var _looping_color : String = ''


signal frame_selected(idx)
signal selected_tags_changed(selected_tags)
signal tag_selected(tag_name)


func _ready():
	clear_options()

	tree.columns = Columns.size()

	tree.set_column_expand(Columns.SELECTED, false)
	tree.set_column_custom_minimum_width(Columns.SELECTED, 32)

	tree.set_column_title(Columns.NAME, "Name")
	tree.set_column_expand(Columns.NAME, true)
	tree.set_column_custom_minimum_width(Columns.START, 48)

	tree.set_column_title(Columns.START, "Start")
	tree.set_column_expand(Columns.START, false)
	tree.set_column_custom_minimum_width(Columns.START, 48)

	tree.set_column_title(Columns.END, "End")
	tree.set_column_expand(Columns.END, false)
	tree.set_column_custom_minimum_width(Columns.END, 48)

	tree.set_column_title(Columns.DIRECTION, "Direction")
	tree.set_column_expand(Columns.DIRECTION, false)
	tree.set_column_custom_minimum_width(Columns.DIRECTION, 84)
	
	tree.set_column_title(Columns.LOOPING, "Loop")
	tree.set_column_expand(Columns.LOOPING, false)
	tree.set_column_custom_minimum_width(Columns.LOOPING, 48)

	tree.set_column_titles_visible(true)

	select_all_button.toggled.connect(_on_SelectAllButton_toggled)
	tree.cell_selected.connect(_on_Tree_cell_selected)
	tree.item_edited.connect(_on_Tree_item_edited)
	
	loopcolor_button.pressed.connect(check_color_code_state)
	for c in color_list.get_children(false):
		if c is CheckBox:
			c.pressed.connect(check_color_code_state)
	
	check_color_code_state()
	


func clear_options() -> void:
	select_all_button.hide()

	for option in _options:
		option.free()
	_options.clear()

	tree.clear()

	_tree_root = tree.create_item()


func load_tags(tags : Array) -> void:
	clear_options()

	if tags == []:
		return

	for tag in tags:
		var new_tree_item := tree.create_item(_tree_root)

		new_tree_item.set_cell_mode(Columns.SELECTED, TreeItem.CELL_MODE_CHECK)
		new_tree_item.set_editable(Columns.SELECTED, true)
		new_tree_item.set_checked(Columns.SELECTED, true)
		new_tree_item.set_selectable(Columns.SELECTED, false)

		new_tree_item.set_text(Columns.NAME, tag.name)

		new_tree_item.set_text(Columns.START, str(floor(tag.from)))
		new_tree_item.set_text_alignment(Columns.START, HORIZONTAL_ALIGNMENT_CENTER)

		new_tree_item.set_text(Columns.END, str(floor(tag.to)))
		new_tree_item.set_text_alignment(Columns.END, HORIZONTAL_ALIGNMENT_CENTER)

		new_tree_item.set_text(Columns.DIRECTION, "  %s" % tag.direction)
		new_tree_item.set_selectable(Columns.DIRECTION, false)
	
		new_tree_item.set_cell_mode(Columns.LOOPING, TreeItem.CELL_MODE_CHECK)
		new_tree_item.set_editable(Columns.LOOPING, true)
		new_tree_item.set_checked(Columns.LOOPING, false)
		if tag.has("color"):
			#COLOR CODED TAGS
			new_tree_item.set_checked(Columns.LOOPING, tag.color == _looping_color)
		new_tree_item.set_selectable(Columns.LOOPING, false)

		_options.append(new_tree_item)

	select_all_button.button_pressed = true
	select_all_button.show()


func get_selected_tags() -> Array:
	var selected_tags := []

	for i in range(_options.size()):
		var item : TreeItem = _options[i]
		if item.is_checked(Columns.SELECTED):
			selected_tags.append(i)

	return selected_tags


func get_looping() -> Array:
	var looping_anims := []

	for i in range(_options.size()):
		var item : TreeItem = _options[i]
		if item.is_checked(Columns.SELECTED):
			looping_anims.append(item.is_checked(Columns.LOOPING))

	return looping_anims


func get_state() -> Dictionary:
	var state := {
		selected_tags = get_selected_tags()
	}

	var selected_item := tree.get_selected()
	if selected_item != null:
		var selected_column := tree.get_selected_column()

		var item_idx := _options.find(selected_item)

		state.selected_cell = Vector2(selected_column, item_idx)

	return state


func set_state(new_state : Dictionary) -> void:
	if new_state.has("selected_tags") and _options != []:
		select_all_button.button_pressed = false

		for tag in new_state.selected_tags:
			_options[tag].set_checked(Columns.SELECTED, true)

		if new_state.has("selected_cell"):
			var selected_cell : Vector2 = new_state.selected_cell
			var tree_item : TreeItem = _options[selected_cell.y]
			var column : int = selected_cell.x

			tree_item.select(column)

			match column:
				Columns.NAME:
					emit_signal("tag_selected", selected_cell.y)
				Columns.START, Columns.END:
					emit_signal("frame_selected", int(tree_item.get_text(column)))


		for option in _options:
			if not option.is_checked(Columns.SELECTED):
				return

		_toggling_option = true
		select_all_button.button_pressed = true
		_toggling_option = false


# Signal Callbacks
func _on_SelectAllButton_toggled(button_pressed : bool) -> void:
	if _toggling_option:
		return

	for option in _options:
		option.set_checked(Columns.SELECTED, button_pressed)

	emit_signal("selected_tags_changed", get_selected_tags())


func _on_Tree_cell_selected() -> void:
	var selected_column := tree.get_selected_column()
	var selected_item := tree.get_selected()

	match selected_column:
		Columns.NAME:
			emit_signal("tag_selected", _options.find(selected_item))
		Columns.START, Columns.END:
			emit_signal("frame_selected", int(selected_item.get_text(selected_column)))


func _on_Tree_item_edited() -> void:
	_toggling_option = true

	if select_all_button.pressed:
		for option in _options:
			if option.is_checked(Columns.SELECTED):
				select_all_button.button_pressed = false
				break
	else:
		var is_all_selected := true
		for option in _options:
			if not option.is_checked(Columns.SELECTED):
				is_all_selected = false
				break

		if is_all_selected:
			select_all_button.button_pressed = true

	_toggling_option = false

	emit_signal("selected_tags_changed", get_selected_tags())

func check_color_code_state() -> void:
	if loopcolor_button.button_pressed:
		for c in color_list.get_children(false):
			if c is CheckBox:
				if c.button_pressed:
					_looping_color = "#" + c.get_child(0).color.to_html()
				c.set_disabled(false)
	else:
		for c in color_list.get_children(false):
			if c is CheckBox:
				c.set_disabled(true)
		_looping_color = ''
