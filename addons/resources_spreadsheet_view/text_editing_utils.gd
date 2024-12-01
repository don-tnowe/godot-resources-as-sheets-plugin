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


static func get_caret_movement_from_key(keycode : int) -> int:
	match keycode:
		KEY_LEFT: 
			return -1
		KEY_RIGHT: 
			return +1
		KEY_HOME: 
			return -2
		KEY_END: 
			return +2

	return 0


static func multi_move_caret(offset : int, edited_cells_text : Array, edit_caret_positions : Array, whole_word : bool) -> bool:
	if offset == -1:
		for i in edit_caret_positions.size():
			edit_caret_positions[i] = _step_cursor(edited_cells_text[i], edit_caret_positions[i], -1, whole_word)

	elif offset == +1:
		for i in edit_caret_positions.size():
			edit_caret_positions[i] = _step_cursor(edited_cells_text[i], edit_caret_positions[i], +1, whole_word)

	elif offset < -1:
		for i in edit_caret_positions.size():
			edit_caret_positions[i] = 0

	elif offset > +1:
		for i in edit_caret_positions.size():
			edit_caret_positions[i] = edited_cells_text[i].length()

	return offset != 0


static func multi_erase_right(values : Array, cursor_positions : Array, whole_word : bool):
	for i in values.size():
		var start_pos : int = cursor_positions[i]
		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], 1, whole_word)

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


static func multi_erase_left(values : Array, cursor_positions : Array, whole_word : bool):
	for i in values.size():
		var start_pos : int = cursor_positions[i]

		cursor_positions[i] = _step_cursor(values[i], cursor_positions[i], -1, whole_word)
		values[i] = (
			values[i].substr(0, cursor_positions[i])
			+ values[i].substr(start_pos)
		)

	return values


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


static func get_caret_rect(cell_text : String, caret_position : int, font : Font, font_size : int, label_padding_left : float, caret_width : float = 2.0) -> Rect2:
	var char_size := Vector2(0, font.get_ascent(font_size))
	var result_pos := Vector2(label_padding_left, 0)
	for j in max(caret_position, 0) + 1:
		if j == 0: continue
		if cell_text.unicode_at(j - 1) == 10:
			# If "\n" found, next line.
			result_pos.x = label_padding_left
			result_pos.y += font.get_ascent(font_size)
			continue

		char_size = font.get_char_size(cell_text.unicode_at(j - 1), font_size)
		result_pos.x += char_size.x

	return Rect2(result_pos, Vector2(2, char_size.y))


static func _step_cursor(text : String, start : int, step : int = 1, whole_word : bool = false) -> int:
	var cur := start
	if whole_word and is_character_whitespace(text, cur + step):
		cur += step

	while true:
		cur += step
		if !whole_word or is_character_whitespace(text, cur):
			if cur > text.length():
				return text.length()

			if cur <= 0:
				return 0

			if whole_word and step < 0:
				return cur + 1

			return cur

	return 0
