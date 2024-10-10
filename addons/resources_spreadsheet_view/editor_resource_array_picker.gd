@tool
extends EditorResourcePicker

signal on_resources_dropped(resources : Array)

var _prepared_for_drop := false
var _drop_hint_label : Label


func _ready():
	resource_changed.connect(_on_resource_changed)
	_drop_hint_label = Label.new()
	_drop_hint_label.text = "[Drop Here to Add!]"
	_drop_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drop_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drop_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_drop_hint_label.hide()
	add_child(_drop_hint_label)


func set_prepared_for_drop(state : bool):
	for x in get_children(true):
		if not x is Popup and (not x is Label):
			x.visible = not state

	_drop_hint_label.visible = state
	custom_minimum_size = size if state else Vector2.ZERO
	_prepared_for_drop = state


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var data_drop_type : StringName = data.get(&"type", &"")
	if data_drop_type != &"files" or data_drop_type != &"resource":
		return true

	set_prepared_for_drop(true)
	return false


func _drop_data(at_position: Vector2, data: Variant):
	var data_drop_type : StringName = data.get(&"type", &"")
	var new_array : Array[Resource] = []
	if data_drop_type == &"files":
		for x in data.files:
			new_array.append(load(x))

	if data_drop_type == &"resource":
		new_array.append(data.resource)

	if new_array.size() == 0:
		return

	edited_resource = new_array[0]
	on_resources_dropped.emit(new_array)


func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if !event.pressed:
			set_prepared_for_drop(false)

	if event is InputEventMouseMotion and not _prepared_for_drop:
		# _can_drop_data() is only called when hovering over the picker. Items must be hidden before that.
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not get_global_rect().has_point(event.global_position):
			set_prepared_for_drop(true)


func _on_resource_changed(new_resource : Resource):
	on_resources_dropped.emit([new_resource])
