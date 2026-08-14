# Feature Specification: Filesystem Tree Presentation & Filtering

**Status:** Approved  
**Feature:** SimpleTree Presentation Filtering  
**Target:** Presentational transformation of in-memory filesystem tree

---

## 1. Feature Summary & Objective

Provide presentation-level filtering of filesystem nodes when rendering the tree in the SimpleTree window. All files and directories beginning with a dot (`.`) are filtered out from the rendered display, preventing internal meta-files and meta-directories (e.g., `.git`, `.gitignore`, `.env`, `.cache`) from cluttering the explorer view.

---

## 2. Functional Requirements

### 2.1 Hidden Node Filtering
* **Dot Prefix Rule:** Any filesystem node (file or directory) whose `name` begins with `.` (dot) must be excluded from the rendered presentation.
* **Subtree Pruning:** When a directory is filtered out, all of its descendant child nodes and subdirectories are omitted from the rendered output.
* **Standard Node Preservation:** Non-dot files and non-dot directories must continue to be displayed with correct hierarchy and indentation.
* **Domain Model Independence:** The filtering occurs during the presentation transformation in `ui.lua`; the underlying in-memory state store (`filesystem.lua`) retains the full, unfiltered tree structure.

### 2.2 Folder & File Icon Presentation
* **Folder State Icons:**
  - Collapsed/closed directory nodes display `FOLDER_ICON_CLOSED` (``) by default.
  - Expanded directory nodes (`node.expanded == true`) display `FOLDER_ICON_OPEN` (``).
* **Icon Providers:**
  - Queries `mini.icons` for directory-specific or file-specific icons if available.
  - Falls back to `nvim-web-devicons` for file icons if `mini.icons` is absent.
  - Falls back gracefully to default folder icons and empty file icon strings if no third-party icon libraries are installed.

---

## 3. Acceptance Criteria (Definition of Done)

### AC-1: Filter Dot Folders & Subtrees
* **Given** a directory containing subdirectories starting with `.` (e.g., `.git`, `.vscode`),
* **When** `ui.renderTree(root)` is executed,
* **Then** the dot directories and all their descendants are omitted from the returned string list.

### AC-2: Filter Dot Files
* **Given** a directory containing files starting with `.` (e.g., `.gitignore`, `.env`),
* **When** `ui.renderTree(root)` is executed,
* **Then** the dotfiles are omitted from the returned string list.

### AC-3: Preserve Non-Dot Nodes
* **Given** a directory containing regular directories and regular files alongside dot-prefixed nodes,
* **When** `ui.renderTree(root)` is executed,
* **Then** only the non-dot directories and files are rendered with appropriate indentation levels.
