# Edit Resources as Table

    "Welp, it does what it sounds like!"

A plugin for Godot 4 that adds a tab for viewing and editing folders of Resources as data tables, one Resource per row. It was made from necessity when trying to develop another plugin.

[Attribution and Contact](https://github.com/don-tnowe/godot-resources-as-sheets-plugin/tree/master?tab=readme-ov-file#attribution-and-contact)

[Godot 3 branch](https://github.com/don-tnowe/godot-resources-as-sheets-plugin/tree/godot-3), [Godot 4 branch](https://github.com/don-tnowe/godot-resources-as-sheets-plugin/tree/Godot-4)

## Features

- Edit Text, Numbers, Colors and Booleans via keyboard, and view Resources, Arrays and Enums editable through Inspector
- Select multiple cells in one column (Shift/Ctrl+Click) to edit them in the Inspector simultaneously.
- Multi-cell text editing right in the table view. Click a cell and type with your keyboard into all selected cells, [move the typing caret with a keyboard input](https://github.com/don-tnowe/godot-resources-as-sheets-plugin/tree/master?tab=readme-ov-file#keyboard-inputs) to make it visible.
- CSV support - Import, Export or Edit directly with strongly-typed columns

---

- Special mass operations for some datatypes
    - Multiply/add numbers
    - Rotate color hues/adjust sat/val/RGB
    - Chop texture into atlas, assign results to each selected resource

![Gif](./images/resources_as_sheet2.gif)

- Sort entries by column
- Filter rows by evaluating GDScript expression
- Filter rows by Resource class/script
- Apply GDScript expression to selected rows
- Row stylization (color-type cells change look of the row until next color-type)
- Saves recently opened folders and hidden columns between sessions
- Full Undo/Redo support.

![Gif](./images/resources_as_sheet3.gif)

## Keyboard Inputs

- `Ctrl + Click / Cmd + Click` - Select multiple cells in one column
- `Shift + Click` - Select all cells between A and B in one column
- `Up / Down / Shift + Tab / Tab` - Move cell selection
---
- `Left / Right` - Move caret along cell text
- `Backspace / Delete` - Erase one character Left / Right from caret
- `Home / End` - Move caret to start/end of cell
- `Ctrl + <move/erase> / Cmd + <move/erase>` - Move through / Erase whole word
---
- `Ctrl / Cmd + C/V` - Copy cells / Paste text into cells (*make sure no scene nodes are selected*)
- `Ctrl / Cmd + D` - Duplicate selected rows (*make sure no scene nodes are selected*)
- `Ctrl / Cmd + R` - Rename resource
- `Ctrl / Cmd + (Shift) + Z` - The Savior

If clipboard contains as many lines as there are cells selected, each line is pasted into a separate cell.

To add support of more datatypes, check out the `typed_cells` and `typed_editors` folders. `typed_cells` need to be added in the `editor_view` root's exported array, and `typed_editors` are placed there under the `%PropertyEditors` node.

## Attribution and Contact

Made by Don Tnowe in 2022.

[License](./LICENSE.md)

[My Website](https://redbladegames.netlify.app)

[My games on Itch](https://don-tnowe.itch.io)

**Need help or want to chat? Message me!** [Telegram](https://t.me/don_tnowe), [Discord](https://discord.com/channels/@me/726139164566880426)

**Did this tool help you so much you'd like to give back?** [Donate via PayPal!](https://redbladegames.netlify.app/tip/index.html)

#

Copying and Modification is allowed in accordance to the MIT license, full text is included.
