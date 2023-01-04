@tool
extends Node
class_name AsepriteImportData


enum Error{
	OK = 0,
	# Error codes start from 49 to not conflict with GlobalScope's error constants
	ERR_JSON_PARSE_ERROR = 49,
	ERR_INVALID_JSON_DATA,
	ERR_MISSING_FRAME_TAGS,
	ERR_EMPTY_FRAME_TAGS
}

const FRAME_TEMPLATE = {
	frame = {
		x = TYPE_INT,
		y = TYPE_INT,
		w = TYPE_INT,
		h = TYPE_INT,
	},
	spriteSourceSize = {
		x = TYPE_INT,
		y = TYPE_INT,
		w = TYPE_INT,
		h = TYPE_INT,
	},
	sourceSize = {
		w = TYPE_INT,
		h = TYPE_INT,
	},
	duration = TYPE_INT,
}

const META_TEMPLATE = {
	frameTags = [
		{
			name = TYPE_STRING,
			from = TYPE_INT,
			to = TYPE_INT,
			direction = TYPE_STRING,
			color = TYPE_STRING
		},
	],
	size = {
		w = TYPE_INT,
		h = TYPE_INT,
	},
}


var json_filepath : String
var json_data : Dictionary


func load(filepath : String) -> int:
#	var file := File.new()
#
#	var error := file.open(filepath, File.READ)
#	if error != OK:
#		return error
	if FileAccess.file_exists(filepath):
		var file = FileAccess.open(filepath,FileAccess.READ)
		
		var file_text = file.get_as_text()
#		file.close()

#		var json := JSON.parse(file_text)
#		if json.error != OK:
		var json = JSON.new()
		if json.parse(file_text) != OK:
			return Error.ERR_JSON_PARSE_ERROR

#		error = _validate_json(json)
		var error = _validate_json(file_text)
		if error != OK:
			return error

		json_filepath = filepath
		json_data = json.data#result

	return OK


func get_frame_array() -> Array:
#	if not json_data:
	if json_data.is_empty():
		return []

	var frame_data = json_data.frames
	if frame_data is Dictionary:
		return frame_data.values()

	return frame_data


func get_image_filename() -> String:
	if not (json_data and json_data.meta.has("image")):
		return ""

	return json_data.meta.image


func get_image_size() -> Vector2:
#	if not json_data:
	if json_data.is_empty():
		return Vector2.ZERO

	var image_size : Dictionary = json_data.meta.size
	return Vector2(
		image_size.w,
		image_size.h
	)


func get_tag(tag_idx : int) -> Dictionary:
	var tags := get_tags()

	if tag_idx >= 0 and tag_idx < tags.size():
		return tags[tag_idx]

	return {}


func get_tags() -> Array:
#	if not json_data:
	if json_data.is_empty():
		return []

	return json_data.meta.frameTags

#is JSONParseResult deprecated? removed static type
#in calls, change parse to string
static func _validate_json(json_string : String) -> int:
	var json = JSON.new()
	var err = json.parse(json_string)
	
	if err != OK:
		return Error.ERR_JSON_PARSE_ERROR
	json.get_data()
	
	
	var data : Dictionary = json.get_data()#json.result

	if not (data is Dictionary and data.has_all(["frames", "meta"])):
		return Error.ERR_INVALID_JSON_DATA

	# "frames" validation
	var frames = data.frames
	var is_hash : bool = frames is Dictionary

	for frame in frames:
		if is_hash:
			frame = frames[frame]

		if not _match_template(frame, FRAME_TEMPLATE):
			return Error.ERR_INVALID_JSON_DATA

	# "meta" validation
	if not _match_template(data.meta, META_TEMPLATE):
		var meta := data.meta as Dictionary

		if not meta.has("frameTags"):
			return Error.ERR_MISSING_FRAME_TAGS
		elif meta.frameTags == []:
			return Error.ERR_EMPTY_FRAME_TAGS

		return Error.ERR_INVALID_JSON_DATA

	return OK


#"""
#This helper function recursively walks an Array or a Dictionary checking if each
#children's type matches the template
#"""
static func _match_template(data, template) -> bool:
	match typeof(template):
		TYPE_INT:
			# When parsed, the JSON interprets integer values as floats
			if template == TYPE_INT and typeof(data) == TYPE_FLOAT:
				return true
			return typeof(data) == template
		TYPE_DICTIONARY:
			if typeof(data) != TYPE_DICTIONARY:
				return false

			if not data.has_all(template.keys()):
				return false

			for key in template:
				if not _match_template(data[key], template[key]):
					return false
		TYPE_ARRAY:
			if typeof(data) != TYPE_ARRAY:
				return false

			if data.is_empty():
				return false

			for element in data:
				if not _match_template(element, template[0]):
					return false

	return true
