@tool
extends Control

@onready var editor_view := $"../../../../.."
@onready var node_options := $"Class"
@onready var node_subclasses_check := $"Subclasses"

var found_builtins : Array[String] = []
var found_scripts : Array[Script] = []
var selected_builtin := &""
var selected_script : Script
var selected_is_valid := false
var include_subclasses := true


func _ready():
	node_options.item_selected.connect(_on_item_selected)
	node_subclasses_check.toggled.connect(_on_subclasses_toggled)


func fill(resources : Array):
	node_options.clear()
	found_scripts.clear()
	found_builtins.clear()
	var class_set := {}
	for x in resources:
		class_set[x.get_script()] = true
		class_set[StringName(x.get_class())] = true
		var current_s : Script = x.get_script()
		while current_s != null:
			current_s = current_s.get_base_script()
			if class_set.has(current_s):
				break

			class_set[current_s] = true

		var current_c : StringName = x.get_class()
		while true:
			if current_c == &"Resource":
				break

			current_c = ClassDB.get_parent_class(current_c)
			if class_set.has(current_c):
				break

			class_set[current_c] = true

	class_set.erase(null)
	class_set.erase("Resource")

	for k in class_set:
		if k is StringName:
			found_builtins.append(k)

		if k is Script:
			found_scripts.append(k)

	# Add builtins, then script classes, in order.
	node_options.add_item("<all>")
	for x in found_builtins:
		node_options.add_item(x)
		if has_theme_icon(x, &"EditorIcons"):
			node_options.set_item_icon(-1, get_theme_icon(x, &"EditorIcons"))

		else:
			node_options.set_item_icon(-1, get_theme_icon(&"Object", &"EditorIcons"))

	for x in found_scripts:
		node_options.add_item(x.resource_path.get_file().get_basename().to_pascal_case())
		node_options.set_item_icon(-1, get_theme_icon(&"Script", &"EditorIcons"))

	node_options.add_item("")

	# Filter is disabled if the already selected class is not in the set.
	if not class_set.has(selected_script) and not class_set.has(selected_builtin):
		selected_is_valid = false

	# When the list is cleared, text and icon are cleared too. Setting to -1 explicitly allows changing icon and label
	node_options.selected = -1
	if not selected_is_valid:
		node_options.set_item_icon(-1, null)

	elif selected_builtin == &"" or selected_builtin == &"Resource":
		node_options.set_item_icon(-1, get_theme_icon("Script", "EditorIcons"))

	else:
		node_options.set_item_icon(-1, get_theme_icon(selected_builtin, "EditorIcons"))

	show()


func clear():
	selected_is_valid = false


func filter(resource : Resource) -> bool:
	if not selected_is_valid:
		return true

	if resource.get_class() != selected_builtin:
		if include_subclasses and selected_script == null:
			var cur_class := StringName(resource.get_class())
			while cur_class != &"Object":
				cur_class = ClassDB.get_parent_class(cur_class)
				if cur_class == selected_builtin:
					return true

		return false

	if selected_script != null and resource.get_script() != selected_script:
		if include_subclasses:
			var cur_class : Script = resource.get_script()
			while cur_class != null:
				cur_class = cur_class.get_base_script()
				if cur_class == selected_script:
					return true

		return false


	return true


func _on_item_selected(index : int):
	if index == 0:
		selected_builtin = &""
		selected_script = null
		selected_is_valid = false

	elif index <= found_builtins.size():
		selected_builtin = found_builtins[index - 1]
		selected_script = null
		selected_is_valid = true

	elif index <= found_builtins.size() + found_scripts.size():
		selected_script = found_scripts[index - found_builtins.size() - 1]
		selected_builtin = selected_script.get_instance_base_type()
		selected_is_valid = true

	node_options.tooltip_text = "Selected: %s" % node_options.get_item_text(index)
	editor_view.refresh()


func _on_subclasses_toggled(state : bool):
	include_subclasses = state
	editor_view.refresh()
