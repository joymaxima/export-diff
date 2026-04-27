# Export Diff

A [Godot 4](https://godotengine.org/) editor plugin that compares two export presets and visualizes which files are exclusive to each, shared between both, or present in the project but missing from either.

---

## Features

- Reads `export_presets.cfg` and lists all preset profiles automatically
- Compares any two presets side by side
- Groups files into four categories:
  - **Only in Profile A** — files exclusive to the first selected preset
  - **Only in Profile B** — files exclusive to the second selected preset
  - **Common in both** — files shared by both presets
  - **In neither** — files found in the project but not included in either preset
- Displays results as a directory tree in the editor dock

---

## Installation

1. Download or clone this repository into your project's `addons/` folder:

```
your_project/
└── addons/
    └── export-diff/
        ├── plugin.cfg
        └── plugin.gd
```

2. Open your project in the Godot editor.
3. Go to **Project → Project Settings → Plugins**.
4. Find **Export Diff** in the list and set it to **Enabled**.

---

## Usage

1. Open your Godot project that has an `export_presets.cfg` file at the project root.
2. In the left dock, find the **Export Diff** panel.
3. Use the **Profile A** and **Profile B** dropdowns to select the two export presets you want to compare.
4. Click **Compare Presets**.
5. The tree view will populate with four categories. Expand any category to browse files by their directory structure.
6. Click a file in the tree to print its full path to the Output console.

---

## Requirements

- Godot **4.x**
- A project with at least one `export_presets.cfg` file

---

## plugin.cfg

```ini
[plugin]
name="Export Diff"
description="Compares two export presets and shows which files are exclusive, shared, or missing."
author="Joy Maxima"
version="1.0"
script="plugin.gd"
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
