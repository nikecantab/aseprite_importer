@tool
extends Node
class_name AsepriteImporter

enum Error{
	OK,
	INVALID_JSON_DATA,
	MISSING_JSON_DATA,
	MISSING_ANIMATION_PLAYER,
	MISSING_SPRITE,
	NO_TAGS_SELECTED,
	DUPLICATE_TAG_NAME,
	MISSING_TEXTURE,
}


static func generate_animations(import_data : AsepriteImportData, selected_tags : Array, looping_anims : Array,
		animation_player : AnimationPlayer, sprite : Node, texture : Texture, library_name : String) -> int:

#	if not(import_data and import_data.json_data):
#	if import_data == null:
#		return Error.MISSING_JSON_DATA
	if import_data.json_data.is_empty():
		return Error.MISSING_JSON_DATA
		
	

	var frame_tags : Array = import_data.get_tags()

	if selected_tags.is_empty():
		return Error.NO_TAGS_SELECTED
	else:
		var tag_names := []
		for tag_idx in selected_tags:
			var tag_name : String = frame_tags[tag_idx].name

			if tag_names.has(tag_name):
				return Error.DUPLICATE_TAG_NAME
			else:
				tag_names.append(tag_name)

	if not animation_player:
		return Error.MISSING_ANIMATION_PLAYER

	if not(sprite is Sprite2D or sprite is Sprite3D):
		return Error.MISSING_SPRITE

	if texture == null:
		return Error.MISSING_TEXTURE

	var animation_root_path := animation_player.root_node
	var animation_root_node := animation_player.get_node(animation_root_path)
	var sprite_relative_path := str(animation_root_node.get_path_to(sprite))

	# These are tracks that will be used
	var tracks := {
		"region" : {
			path = (sprite_relative_path + ":region_rect"),
		},
		"offset" : {
			path = (sprite_relative_path + ":offset")
		}
	}

	var frames := import_data.get_frame_array()
	var is_sprite3d := sprite is Sprite3D
	var animation_lib : AnimationLibrary
	
	
	var lib_name = library_name as StringName
	
	var libraries = animation_player.get_animation_library_list()
	if libraries.has(lib_name):
		animation_lib = animation_player.get_animation_library(lib_name)
	else:
		animation_lib = AnimationLibrary.new()
		animation_player.add_animation_library(lib_name, animation_lib)
	
	# Iterate over each tag (animation)
	for tag_idx in selected_tags:
		var tag : Dictionary = frame_tags[tag_idx]

		var animation : Animation
		# Check if the animation already exists
		if animation_lib.has_animation(tag.name as StringName):
			animation = animation_lib.get_animation(tag.name as StringName)
		else:
			# If it doesn't, adds a new one
			animation = Animation.new()
			# warning-ignore:return_value_discarded
			animation_lib.add_animation(tag.name as StringName, animation)

		#Set Looping
#		animation.set_loop(looping_anims[tag_idx])
		if looping_anims[tag_idx]:
			animation.set_loop_mode(1)
		else:
			animation.set_loop_mode(0)
		
		# Setup the animation tracks
		for track_name in tracks:
			var track : Dictionary = tracks[track_name]

			track.idx = animation.find_track(track.path, Animation.TYPE_VALUE)

			# Checks if the track doesn't  exist
			if track.idx == -1:
				# Create a new_track
				track.idx = animation.add_track(Animation.TYPE_VALUE)
				animation.track_set_path(track.idx, track.path)
			else:
				# Remove all existing keys from the track
				for key_idx in range(animation.track_get_key_count(track.idx)):
					animation.track_remove_key(track.idx, 0)

			# Set the track Interpolation Mode to Nearest
			animation.track_set_interpolation_type(track.idx, Animation.INTERPOLATION_NEAREST)
			#Enable the track
			animation.track_set_enabled(track.idx, true)

		var time := 0.0
		var frame_idxs := range(tag.from, tag.to + 1)

		# Modify the frame order based on the tag's direction
		match tag.direction:
			"reverse":
				frame_idxs.reverse()
			"pingpong":
				animation.set_loop_mode(2)

		# Insert the new keys
		for i in frame_idxs:
			var frame : Dictionary = frames[i]

			# Get the region of the spritesheet that has the frame
			var rect = frame.frame
			var region = Rect2(rect.x, rect.y, rect.w, rect.h)

			# Insert the new key for the region track
			animation.track_insert_key(tracks.region.idx, time, region)

			# Get the center of the frame in the original size
			var source_size : Dictionary = frame.sourceSize
			var source_center_x : float = source_size.w / 2
			var source_center_y : float = source_size.h / 2

			# Get the center of the trimmed frame in the spritesheet
			var trim_rect : Dictionary = frame.spriteSourceSize
			var trim_rect_center_x : float = trim_rect.x + (trim_rect.w / 2)
			var trim_rect_center_y : float = trim_rect.y + (trim_rect.h / 2)

			# Calculate the offset between the trimmed frame center and original frame center
			var offset_x := trim_rect_center_x - source_center_x
			var offset_y := trim_rect_center_y - source_center_y

			# Invert the vertical offset when the selected sprite is a Sprite3D
			if is_sprite3d:
				offset_y *= -1

			# Insert the new key for the offset track
			animation.track_insert_key(tracks.offset.idx, time, Vector2(offset_x, offset_y))

			# Add up the current frame's duration for the next key position
			time += frame.duration / 1000

		# Set the animation length equal to the sum of all frame's durations
		animation.length = time

	sprite.texture = texture
	sprite.region_enabled = true
	sprite.centered = true

	return OK
