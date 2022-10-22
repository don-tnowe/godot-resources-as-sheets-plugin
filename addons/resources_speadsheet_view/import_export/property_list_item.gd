tool
extends HBoxContainer


func display(name : String, type : int):
  $"LineEdit".text = name
  $"OptionButton".selected = type


func connect_all_signals(to : Object, index : int, prefix : String = "_on_list_item_"):
  $"LineEdit".connect("text_changed", to, prefix + "name_changed", [index])
  $"OptionButton".connect("item_selected", to, prefix + "type_selected", [index])
