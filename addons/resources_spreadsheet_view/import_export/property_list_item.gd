@tool
extends HBoxContainer


func display(name : String, type : int):
  $"LineEdit".text = name
  $"OptionButton".selected = type


func connect_all_signals(to : Object, index : int, prefix : String = "_on_list_item_"):
  $"LineEdit".text_changed.connect(Callable(to, prefix + "name_changed").bind(index))
  $"OptionButton".item_selected.connect(Callable(to, prefix + "type_selected").bind(index))
