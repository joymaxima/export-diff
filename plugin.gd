@tool
extends EditorPlugin

var panel: VBoxContainer
var tree: Tree
var option_a: OptionButton
var option_b: OptionButton
var track_button: Button

func _enter_tree():
	panel = VBoxContainer.new()
	panel.name = "Export Diff"

	# Preset selectors
	var label_a = Label.new()
	label_a.text = "Profile A:"
	panel.add_child(label_a)

	option_a = OptionButton.new()
	panel.add_child(option_a)

	var label_b = Label.new()
	label_b.text = "Profile B:"
	panel.add_child(label_b)

	option_b = OptionButton.new()
	panel.add_child(option_b)

	_populate_preset_options()

	# Track button
	track_button = Button.new()
	track_button.text = "Compare Presets"
	track_button.pressed.connect(_run_comparison)
	panel.add_child(track_button)

	# Tree
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.columns = 1
	tree.hide_root = true
	tree.item_selected.connect(_on_item_selected)
	panel.add_child(tree)

	add_control_to_dock(DOCK_SLOT_LEFT_UR, panel)

func _exit_tree():
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()

func _populate_preset_options():
	option_a.clear()
	option_b.clear()

	var config = ConfigFile.new()
	var path = "res://export_presets.cfg"

	if not FileAccess.file_exists(path):
		printerr("Error: export_presets.cfg not found!")
		return

	var err = config.load(path)
	if err != OK:
		printerr("Error: failed to load export_presets.cfg!")
		return

	# Collect all preset names
	for section in config.get_sections():
		var preset_name = config.get_value(section, "name", "")
		if preset_name != "":
			option_a.add_item(preset_name)
			option_b.add_item(preset_name)

	# Default second option to index 1 if available to avoid same-same default
	if option_b.item_count > 1:
		option_b.select(1)

func _run_comparison():
	var config = ConfigFile.new()
	var path = "res://export_presets.cfg"

	if not FileAccess.file_exists(path):
		printerr("Error: export_presets.cfg not found!")
		return

	var err = config.load(path)
	if err != OK:
		printerr("Error: failed to load export_presets.cfg!")
		return

	var selected_a = option_a.get_item_text(option_a.selected)
	var selected_b = option_b.get_item_text(option_b.selected)

	var files_a: Array = []
	var files_b: Array = []

	for section in config.get_sections():
		var preset_name = config.get_value(section, "name", "")
		if preset_name == selected_a:
			files_a = _parse_export_files(config.get_value(section, "export_files", ""))
		elif preset_name == selected_b:
			files_b = _parse_export_files(config.get_value(section, "export_files", ""))

	var only_a  = files_a.filter(func(i): return not files_b.has(i))
	var only_b  = files_b.filter(func(i): return not files_a.has(i))
	var common  = files_a.filter(func(i): return files_b.has(i))

	var all_files = _scan_dir("res://")
	var both = files_a + files_b
	var nowhere = all_files.filter(func(i): return not both.has(i))

	_update_tree_visuals(selected_a, selected_b, only_a, only_b, common, nowhere)

func _parse_export_files(raw_value) -> Array:
	if typeof(raw_value) == TYPE_STRING:
		return Array(raw_value.split(",")) if raw_value != "" else []
	elif typeof(raw_value) == TYPE_PACKED_STRING_ARRAY or typeof(raw_value) == TYPE_ARRAY:
		return Array(raw_value)
	return []

func _scan_dir(path: String) -> Array:
	var result: Array = []
	var dir = DirAccess.open(path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname == "." or fname == ".." or fname == ".godot":
			fname = dir.get_next()
			continue
		var full = (path + "/" + fname).replace("res:///", "res://")
		if dir.current_is_dir():
			result.append_array(_scan_dir(full))
		else:
			if not fname.ends_with(".import") and not fname.ends_with(".uid"):
				result.append(full)
		fname = dir.get_next()
	dir.list_dir_end()
	return result

func _update_tree_visuals(name_a: String, name_b: String, only_a: Array, only_b: Array, common: Array, nowhere: Array):
	tree.clear()
	var root = tree.create_item()

	_add_category(root, "Only in %s (%d)"  % [name_a, only_a.size()],  only_a)
	_add_category(root, "Only in %s (%d)"  % [name_b, only_b.size()],  only_b)
	_add_category(root, "Common in both (%d)"  % common.size(),         common)
	_add_category(root, "In neither (%d)"      % nowhere.size(),        nowhere)

func _add_category(root: TreeItem, label: String, files: Array):
	var cat_node = tree.create_item(root)
	cat_node.set_text(0, label)

	# Cache directory nodes to avoid duplicates: "res://some/dir" -> TreeItem
	var dir_nodes: Dictionary = {}

	for file in files:
		var rel = file.trim_prefix("res://")
		var parts = rel.split("/")

		var current_parent: TreeItem = cat_node
		var built_path: String = "res:/"

		# Build directory chain down to the file
		for i in range(parts.size() - 1):
			built_path += "/" + parts[i]
			if not dir_nodes.has(built_path):
				var dir_item = tree.create_item(current_parent)
				dir_item.set_text(0, parts[i])
				dir_item.set_metadata(0, null)
				dir_nodes[built_path] = dir_item
			current_parent = dir_nodes[built_path]

		# Add file leaf node
		var file_item = tree.create_item(current_parent)
		file_item.set_text(0, parts[-1])
		file_item.set_metadata(0, file)

func _on_item_selected():
	var selected = tree.get_selected()
	if selected and selected.get_metadata(0) != null:
		print("Selected file path: ", selected.get_metadata(0))
