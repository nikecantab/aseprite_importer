@tool
extends Container


@onready var clear_button : Button = find_child("ClearButton")
@onready var line_edit : LineEdit = find_child("LineEdit")

var library_name : String : 
	set(value):
		if value == '':
			clear_button.hide()
		else:
			clear_button.show()
		line_edit.text = value
	get:
		return line_edit.text


func _ready() -> void:
	clear_button.pressed.connect(_on_ClearButton_pressed)
	
	
func initialize_text(initial_name: String) -> void:
	library_name = initial_name
	line_edit.editable = true

func forbid_text() -> void:
	library_name = ''
	line_edit.editable = false


func _on_ClearButton_pressed() -> void:
	library_name = ''
	
