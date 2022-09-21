tool
extends SheetsDockEditor


func can_edit_value(value, type, property_hint) -> bool:
  return type == TYPE_COLOR
