# Edit Resources as Spreadsheet

    "Welp, it is what it sounds like!"

A plugin for Godot 3 that adds a tab for editing folders of Resources as data tables. It was made from neccessity when trying to develop another plugin.

- Multi-cell text editing (visible cursor not included, unfortunately)
- Copy-paste Text into Cells (one line, one cell)
- Sort entries by column
- Search by evaluating GDScript expression
- Saves recently opened folders between sessions.

Possible inputs:
- `Ctrl + Click / Cmd + Click` - Select multiple cells in one column
- `Shift + Click` - Select all cells between A and B in one column
- `Left/Right` - Move cursor along cell text
- `Backspace/Delete` - Erase text Left / Right from cursor
- `Home/End` - Move cursor to start/end of cell
- `Ctrl + <move/erase> / Cmd + <move/erase>` - Move through / Erase whole word
- `Ctrl/Cmd + C/V` - Copy cells / Paste text into cells 
- `Ctrl/Cmd + (Shift) + Z` - The Savior

If clipboard contains as many lines as there are cells selected, each line is pasted into a separate cell.

Support of more data types coming eventually.

#

Made by Don Tnowe in 2022.

[https://redbladegames.netlify.app]()

[https://twitter.com/don_tnowe]()
