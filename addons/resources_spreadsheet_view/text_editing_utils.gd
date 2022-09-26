class_name TextEditingUtils
extends RefCounted

const non_typing_paragraph := "¶"
const non_typing_space := "●"
const whitespace_chars := [
	32, # " "
	44, # ","
	58, # ":"
	45, # "-"
	59, # ";"
	40, # "("
	41, # ")"
	46, # "."
	182, # "¶" Linefeed
	967, # "●" Whitespace
]


static func is_character_whitespace(text : String, idx : int) -> bool:
	if idx <= 0: return true  # Stop at the edges.
	if idx >= text.length(): return true
	return text.unicode_at(idx) in whitespace_chars


static func show_non_typing(text : String) -> String:
	text = text\
		.replace(non_typing_paragraph, "\n")\
		.replace(non_typing_space, " ")
	
	if text.ends_with("\n"):
		text = text.left(text.length() - 1) + non_typing_paragraph

	elif text.ends_with(" "):
		text = text.left(text.length() - 1) + non_typing_space

	return text


static func revert_non_typing(text : String) -> String:
	if text.ends_with(non_typing_paragraph):
		text = text.left(text.length() - 1) + "\n"

	elif text.ends_with(non_typing_space):
		text = text.left(text.length() - 1) + " "

	return text


static func multi_erase_right(values : Array, cursor_positions : Array, ctrl_pressed : bool):
	for i in values.size():
		var start_pos = cursor_positions[i]
		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], 1, ctrl_pressed)

		cursor_positions[i] = min(
			cursor_positions[i], 
			values[i].length()
		)
		values[i] = (
			values[i].left(start_pos)
			+ values[i].substr(cursor_positions[i])
		)
		cursor_positions[i] = start_pos

	return values


static func multi_erase_left(values : Array, cursor_positions : Array, ctrl_pressed):
	for i in values.size():
		var start_pos = cursor_positions[i]

		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], -1, ctrl_pressed)
		values[i] = (
			values[i].substr(0, cursor_positions[i])
			+ values[i].substr(start_pos)
		)

	return values


static func multi_move_left(values : Array, cursor_positions : Array, ctrl_pressed):
	for i in cursor_positions.size():
		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], -1, ctrl_pressed)


static func multi_move_right(values : Array, cursor_positions : Array, ctrl_pressed):
	for i in cursor_positions.size():
		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], 1, ctrl_pressed)


static func multi_paste(values : Array, cursor_positions : Array):
	var pasted_lines := DisplayServer.clipboard_get().split("\n")
	var paste_each_line := pasted_lines.size() == values.size()

	for i in values.size():
		if paste_each_line:
			cursor_positions[i] += pasted_lines[i].length()

		else:
			cursor_positions[i] += OS.clipboard.length()
		
		values[i] = (
			values[i].left(cursor_positions[i])
			+ (pasted_lines[i] if paste_each_line else OS.clipboard)
			+ values[i].substr(cursor_positions[i])
		)

	return values


static func multi_copy(values : Array):
	for i in values.size():
		values[i] = values[i]
	
	DisplayServer.clipboard_set("\n".join(values))


static func multi_input(input_char : String, values : Array, cursor_positions : Array):
	for i in values.size():
		values[i] = (
			values[i].left(cursor_positions[i])
			+ input_char
			+ values[i].substr(cursor_positions[i])
		)
		cursor_positions[i] = min(cursor_positions[i] + 1, values[i].length())

	return values


static func _step_cursor(text : String, start : int, step : int = 1, ctrl_pressed : bool = false) -> int:
	while true:
		start += step
		if !ctrl_pressed or is_character_whitespace(text, start):
			if start > text.length():
				return text.length()

			if start < 0:
				return 0

			return start

	return 0


static func string_snake_to_naming_case(string : String, add_spaces : bool = true) -> String:
	if string == "": return ""

	var split = string.split("_")
	for i in split.size():
		split[i] = split[i][0].to_upper() + split[i].substr(1).to_lower()
	
	return (" " if add_spaces else "").join(split)


static func pascal_case_to_snake_case(string : String) -> String:
	var i = 0
	while i < string.length():
		if string.unicode_at(i) < 97:
			string = string.left(i) + ("_" if i > 0 else "") + string[i].to_lower() + string.substr(i + 1)
			i += 1
		
		i += 1

	return string
