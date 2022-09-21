class_name TextEditingUtils
extends Reference

const non_typing_paragraph := "¶"
const non_typing_space := "●"
const whitespace_chars := [
	ord(" "), 
	ord(","), 
	ord(":"), 
	ord("-"), 
	ord(";"), 
	ord("("), 
	ord(")"), 
	ord("."), 
	ord(non_typing_paragraph), 
	ord(non_typing_space),
]


static func is_character_whitespace(text : String, idx : int) -> bool:
	if idx <= 0: return true  # Stop at the edges.
	if idx >= text.length(): return true
	return text.ord_at(idx) in whitespace_chars


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


static func multi_erase_right(edited_cells : Array, edit_cursor_positions : Array, callback_object : Object):
	for i in edited_cells.size():
		var cell = edited_cells[i]
		var start_pos = edit_cursor_positions[i]
		while true:
			edit_cursor_positions[i] += 1
			if !Input.is_key_pressed(KEY_CONTROL) or is_character_whitespace(cell.text, edit_cursor_positions[i]):
				break

		edit_cursor_positions[i] = min(
			edit_cursor_positions[i], 
			edited_cells[i].text.length()
		)
		callback_object.set_cell(cell, (
			cell.text.left(start_pos)
			+ cell.text.substr(edit_cursor_positions[i])
		))
		edit_cursor_positions[i] = start_pos


static func multi_erase_left(edited_cells : Array, edit_cursor_positions : Array, callback_object : Object):
	for i in edited_cells.size():
		var cell = edited_cells[i]
		var start_pos = edit_cursor_positions[i]

		edit_cursor_positions[i] = _step_cursor(cell.text, edit_cursor_positions[i], -1)
		var result_text = (
			cell.text.substr(0, edit_cursor_positions[i])
			+ cell.text.substr(start_pos)
		)
		callback_object.set_cell(cell, (
			cell.text.substr(0, edit_cursor_positions[i])
			+ cell.text.substr(start_pos)
		))


static func multi_move_left(edited_cells : Array, edit_cursor_positions : Array):
	for i in edit_cursor_positions.size():
		edit_cursor_positions[i] = _step_cursor(edited_cells[i].text, edit_cursor_positions[i], -1)


static func multi_move_right(edited_cells : Array, edit_cursor_positions : Array):
	for i in edit_cursor_positions.size():
		edit_cursor_positions[i] = _step_cursor(edited_cells[i].text, edit_cursor_positions[i], 1)


static func multi_paste(edited_cells : Array, edit_cursor_positions : Array, callback_object : Object):
	var pasted_lines := OS.clipboard.split("\n")
	var paste_each_line := pasted_lines.size() == edited_cells.size()

	for i in edited_cells.size():
		if paste_each_line:
			edit_cursor_positions[i] += pasted_lines[i].length()

		else:
			edit_cursor_positions[i] += OS.clipboard.length()
		
		var cell = edited_cells[i]
		callback_object.set_cell(cell, (
			cell.text.left(edit_cursor_positions[i])
			+ (pasted_lines[i] if paste_each_line else OS.clipboard)
			+ cell.text.substr(edit_cursor_positions[i])
		))


static func multi_copy(edited_cells : Array):
	var copied_text := ""

	for i in edited_cells.size():
		copied_text += "\n" + edited_cells[i].text
	
	# Cut the first \n out.
	OS.clipboard = copied_text.substr(1)


static func multi_linefeed(edited_cells : Array, edit_cursor_positions : Array, callback_object : Object):
	for i in edited_cells.size():
		var cell = edited_cells[i]
		callback_object.set_cell(cell, (
			cell.text.left(edit_cursor_positions[i])
			+ "\n"
			+ cell.text.substr(edit_cursor_positions[i])
		))
		edit_cursor_positions[i] = min(edit_cursor_positions[i] + 1, cell.text.length())


static func multi_input(input_char : String, edited_cells : Array, edit_cursor_positions : Array, callback_object : Object):
	for i in edited_cells.size():
		var cell = edited_cells[i]
		callback_object.set_cell(cell, (
				cell.text.left(edit_cursor_positions[i])
				+ input_char
				+ cell.text.substr(edit_cursor_positions[i])
		))
		edit_cursor_positions[i] = min(edit_cursor_positions[i] + 1, cell.text.length())


static func _step_cursor(text : String, start : int, step : int = 1) -> int:
	while true:
		start += step
		if !Input.is_key_pressed(KEY_CONTROL) or is_character_whitespace(text, start):
			if start > text.length():
				return text.length()

			if start < 0:
				return 0

			return start

	return 0
