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
	10, # "\n" Actual Linefeed
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


static func multi_erase_left(values : Array, cursor_positions : Array, ctrl_pressed : bool):
	for i in values.size():
		var start_pos = cursor_positions[i]

		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], -1, ctrl_pressed)
		values[i] = (
			values[i].substr(0, cursor_positions[i])
			+ values[i].substr(start_pos)
		)

	return values


static func multi_move_left(values : Array, cursor_positions : Array, ctrl_pressed : bool):
	for i in cursor_positions.size():
		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], -1, ctrl_pressed)


static func multi_move_right(values : Array, cursor_positions : Array, ctrl_pressed : bool):
	for i in cursor_positions.size():
		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], 1, ctrl_pressed)


static func multi_paste(values : Array, cursor_positions : Array):
	var pasted_lines := DisplayServer.clipboard_get().replace("\r", "").split("\n")
	var paste_each_line := pasted_lines.size() == values.size()

	for i in values.size():
		if paste_each_line:
			cursor_positions[i] += pasted_lines[i].length()

		else:
			cursor_positions[i] += DisplayServer.clipboard_get().length()

		values[i] = (
			values[i].left(cursor_positions[i])
			+ (pasted_lines[i] if paste_each_line else DisplayServer.clipboard_get())
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
	var cur := start
	if ctrl_pressed and is_character_whitespace(text, cur + step):
		cur += step

	while true:
		cur += step
		if !ctrl_pressed or is_character_whitespace(text, cur):
			if cur > text.length():
				return text.length()

			if cur <= 0:
				return 0

			if ctrl_pressed and step < 0:
				return cur + 1

			return cur

	return 0
