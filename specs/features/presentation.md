# Feature Specification: Filesystem Tree Presentation, Filtering & Highlights

**Status:** Approved  
**Feature:** SimpleTree Presentation Filtering, Sorting & Highlighting  
**Target:** Presentational transformation of in-memory filesystem tree into decorated UI items

---

## 1. Feature Summary & Objective

Provide presentation-level filtering, structured ordering, and visual syntax highlighting of filesystem nodes when rendering the tree in the SimpleTree window. All files and directories beginning with a dot (`.`) are filtered out from the rendered display. Within each directory level, folders are sorted and displayed before files, with alphabetical ordering within each group.

The presentation transformation produces a structured list of items (`TreeItem[]`), where each item includes the line text, the associated node ID, and a list of byte-accurate extmark highlight spans (`Extmark[]`) to decorate icons, directory labels, and file labels.

---

## 2. Functional Requirements

### 2.1 Presentational Data Model (`TreeItem` & `Extmark`)
* `ui.renderTree(root)` returns an array of items (`TreeItem[]`):
  - `line: string` — The formatted line string with indentation prefix and icons.
  - `id: number|nil` — The unique ID of the corresponding node in the filesystem domain model.
  - `extmarks: Extmark[]` — A list of extmark highlight decorations for the line.
* Each `Extmark` contains:
  - `col_start: number` — 0-indexed starting byte offset of the highlight range.
  - `col_end: number` — 0-indexed exclusive ending byte offset of the highlight range.
  - `highlight: string` — The highlight group name (e.g., `SimpleTreeFolderIcon`, `SimpleTreeDirectory`, `SimpleTreeFile`, `SimpleTreeIcon`, or third-party devicon/miniicon group).

### 2.2 Highlight Groups & Styling Scheme
* **Standard Highlight Groups:**
  - `SimpleTreeFolderIcon`: Highlight group for default folder state icons (``, ``).
  - `SimpleTreeDirectory`: Highlight group for directory node names.
  - `SimpleTreeFile`: Highlight group for file node names.
  - `SimpleTreeIcon`: Highlight group for general file/folder icons and fallback glyphs.
  - **Dynamic Highlight Groups:** When resolved from third-party icon providers (`mini.icons` or `nvim-web-devicons`), the provider's associated highlight group is used.
* **Byte Offset Precision:** Extmark column boundaries are calculated in bytes to accurately support multibyte UTF-8 icon glyphs (e.g., 3-byte folder icons) and indentation spaces.

### 2.3 Hidden Node Filtering
* **Dot Prefix Rule:** Any filesystem node (file or directory) whose `name` begins with `.` (dot) must be excluded from the rendered presentation.
* **Subtree Pruning:** When a directory is filtered out, all of its descendant child nodes and subdirectories are omitted from the rendered output.
* **Standard Node Preservation:** Non-dot files and non-dot directories must continue to be displayed with correct hierarchy and indentation.
* **Domain Model Independence:** The filtering occurs during the presentation transformation in `ui.lua`; the underlying in-memory state store (`model`) retains the full, unfiltered tree structure.

### 2.4 Folder & File Icon Presentation
* **Folder State Icons:**
  - Collapsed/closed directory nodes display `FOLDER_ICON_CLOSED` (``) by default.
  - Expanded directory nodes (`node.expanded == true`) display `FOLDER_ICON_OPEN` (``).
* **Icon Providers:**
  - Queries `mini.icons` for directory-specific or file-specific icons if available.
  - Falls back to `nvim-web-devicons` for file icons if `mini.icons` is absent.
  - Falls back gracefully to default folder icons and empty file icon strings if no third-party icon libraries are installed.

### 2.5 Folders-First Ordering & Sorting
* **Folders Precedence:** At every directory level, all directory nodes (`type == "directory"`) must appear before file nodes (`type ~= "directory"`).
* **Alphabetical Ordering:** Within the directories group and files group respectively, items are sorted alphabetically in a case-insensitive manner (`a.name:lower() < b.name:lower()`).
* **Immutability:** Sorting must not mutate the internal domain tree structure in `model`.

---

## 3. Acceptance Criteria (Definition of Done)

### AC-1: Filter Dot Folders & Subtrees
* **Given** a directory containing subdirectories starting with `.` (e.g., `.git`, `.vscode`),
* **When** `ui.renderTree(root)` is executed,
* **Then** the dot directories and all their descendants are omitted from the returned item list.

### AC-2: Filter Dot Files
* **Given** a directory containing files starting with `.` (e.g., `.gitignore`, `.env`),
* **When** `ui.renderTree(root)` is executed,
* **Then** the dotfiles are omitted from the returned item list.

### AC-3: Preserve Non-Dot Nodes
* **Given** a directory containing regular directories and regular files alongside dot-prefixed nodes,
* **When** `ui.renderTree(root)` is executed,
* **Then** only the non-dot directories and files are rendered with appropriate indentation levels and node IDs.

### AC-4: Folders-First & Alphabetical Sorting
* **Given** a directory containing a mix of unsorted files and folders (e.g., `main.lua`, `src/`, `README.md`, `assets/`, `config.lua`),
* **When** `ui.renderTree(root)` is executed,
* **Then** folders appear first in alphabetical order (`assets/`, `src/`), followed by files in alphabetical order (`config.lua`, `main.lua`, `README.md`).

### AC-5: Extmark Generation & Highlight Span Calculation
* **Given** a tree containing directory nodes, file nodes, and icons,
* **When** `ui.renderTree(root)` is executed,
* **Then** each item contains accurate `extmarks` with `col_start`, `col_end`, and `highlight` matching the byte boundaries of the icon glyph and node name.
