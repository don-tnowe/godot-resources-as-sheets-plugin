@tool
extends Container

var visible_column_minsizes : Array = []:
	set(v):
		visible_column_minsizes = v
		queue_sort()
var visible_column_positions : Array[float] = []
var _cached_minimum_size := Vector2.ZERO


func _notification(what : int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var visible_children : Array[Control] = []
		for x in get_children():
			if x is Control and x.visible:
				visible_children.append(x)

		sort_children(visible_children)


func _get_minimum_size() -> Vector2:
	return _cached_minimum_size


func get_visible_column_position(index : int):
	pass


func sort_children(children : Array[Control]) -> void:
	var column_count := visible_column_minsizes.size()
	if column_count == 0:
		return

	var column_minsizes : Array[float] = []
	var row_minsizes : Array[float] = []
	column_minsizes.resize(column_count)
	row_minsizes.resize(children.size() / column_count + 1)

	for i in visible_column_minsizes.size():
		column_minsizes[i] = visible_column_minsizes[i]

	var current_cell := Vector2i.ZERO
	for x in children:
		var minsize := x.get_combined_minimum_size()
		column_minsizes[current_cell.x] = maxf(column_minsizes[current_cell.x], minsize.x)
		row_minsizes[current_cell.y] = maxf(row_minsizes[current_cell.y], minsize.y)
		current_cell.x += 1
		if current_cell.x == column_count:
			current_cell.x = 0
			current_cell.y += 1

	var current_pos := Vector2.ZERO
	current_cell = Vector2i.ZERO
	for x in children:
		var cur_size := Vector2(column_minsizes[current_cell.x], row_minsizes[current_cell.y])
		fit_child_in_rect(x, Rect2(current_pos, cur_size))
		current_pos.x += cur_size.x
		current_cell.x += 1
		if current_cell.x == column_count:
			current_cell.x = 0
			current_cell.y += 1
			current_pos.x = 0.0
			current_pos.y += cur_size.y

	_cached_minimum_size = Vector2.ZERO
	visible_column_positions.resize(column_minsizes.size() + 1)
	for i in column_minsizes.size():
		_cached_minimum_size.x += column_minsizes[i]
		visible_column_positions[i + 1] = _cached_minimum_size.x

	for x in row_minsizes:
		_cached_minimum_size.y += x
