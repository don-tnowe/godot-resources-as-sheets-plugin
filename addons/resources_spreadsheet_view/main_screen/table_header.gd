@tool
extends HBoxContainer

var manager : Control


func set_label(label : String):
	$"Button".text = label.capitalize()
	$"Button".tooltip_text = label + "\nClick to sort."


func _ready():
	$"Button".gui_input.connect(_on_main_gui_input)
	$"Button2".about_to_popup.connect(_on_about_to_popup)
	$"Button2".get_popup().id_pressed.connect(_on_list_id_pressed)


func _on_about_to_popup():
	var menu_popup : PopupMenu = $"Button2".get_popup()
	menu_popup.clear()
	menu_popup.add_item("Select All", 0)
	menu_popup.add_item("Hide", 1)

	if !manager.editor_view.column_can_solo_open(get_index()):
		menu_popup.add_item("(not a Resource property)", 2)
		menu_popup.set_item_disabled(2, true)
		menu_popup.add_separator("", 3)

	else:
		menu_popup.add_item("Open Sub-Resources of Column", 2)

		if manager.editor_view.get_edited_cells_values().size() == 0 or manager.editor_view.get_selected_column() != get_index():
			menu_popup.add_item("(none selected)", 3)
			menu_popup.set_item_disabled(3, true)

		else:
			menu_popup.add_item("Open Sub-Resources in Selection", 3)


func _on_main_gui_input(event : InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var popup : Popup = $"Button2".get_popup()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_on_about_to_popup()
			popup.visible = !popup.visible
			popup.size = Vector2.ZERO
			popup.position = Vector2i(get_global_mouse_position()) + get_viewport().position

		else:
			popup.visible = false


func _on_list_id_pressed(id : int):
	match id:
		0:
			manager.select_column(get_index())
		1:
			manager.hide_column(get_index())
		2:
			manager.editor_view.column_solo_open(get_index())
		3:
			var resources_to_open_unique := {}
			for x in manager.editor_view.get_edited_cells_values():
				if x is Array:
					for y in x:
						resources_to_open_unique[y] = true

				if x is Resource:
					resources_to_open_unique[x] = true

			if resources_to_open_unique.size() > 0:
				manager.editor_view.display_resources(resources_to_open_unique.keys())
