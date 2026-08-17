# Feature Specification: Tree Navigation & Directory Expansion

**Status:** Approved  
**Feature:** SimpleTree Navigation, Node Expansion & File Opening  
**Target:** Buffer keymaps, tree expansion lifecycle, and editor window targeting

---

## 1. Feature Summary & Objective

Provide buffer-local keymaps and domain actions to toggle (expand/collapse) directory nodes and open file nodes within the SimpleTree explorer window. Expanding a directory reveals its child files and subdirectories, while collapsing a directory hides its descendants. Activating a file node on `<CR>` opens the file in the editor window immediately to the right of the SimpleTree sidebar.

---

## 2. Keybinding Interface

Inside the `simple-tree` filetype buffer, the following default buffer-local keybindings are available:

| Keymap | Action | Target Node Type | Description |
| :--- | :--- | :--- | :--- |
| `<CR>` | Select Node | Directory / File | If directory: expands/collapses folder. If file: opens file in the window to the right. |
| `<Space>` | Toggle Expansion | Directory | Expands the directory if collapsed; collapses it if expanded. No-op on files. |

---

## 3. Functional Requirements

### 3.1 Expansion State Management
* **In-Memory State (`node.expanded`):** Directory expansion state is tracked in the in-memory tree domain model (`filesystem.lua`).
* **Initial State:** Non-root directories default to collapsed (`expanded = false` or `nil`) upon initial workspace scan.
* **Lazy / On-Demand Traversal:** If a directory's children have not yet been loaded into memory, expanding the node triggers an asynchronous directory scan before re-rendering.
* **State Toggle Immutability:** Toggling expansion updates the domain tree state and preserves existing child hierarchy states.

### 3.2 View Synchronization & UI Re-rendering
* **Selective Re-render:** Toggling expansion triggers `ui.renderTree` and updates the scratch buffer contents.
* **Icon State Update:**
  - Collapsed directories display `FOLDER_ICON_CLOSED` (``).
  - Expanded directories display `FOLDER_ICON_OPEN` (``).
* **Cursor Position Preservation:** The cursor remains on the toggled directory node line after the buffer content is refreshed.

### 3.3 File Node Activation & Window Targeting
* **Open in Right Window:** When `<CR>` is invoked on a file node (`type == "file"`), the plugin opens the target file path in the window immediately to the right of the SimpleTree sidebar.
* **Split Creation Fallback:** If no window exists to the right of the SimpleTree window (e.g. SimpleTree is the only window), a new vertical split is created to the right (`rightbelow vsplit`), and the file is loaded into that split.
* **Focus Transition:** Input focus shifts to the target window displaying the opened file.
* **Non-destructive Space Keymap:** Pressing `<Space>` on a file node performs a graceful no-op without raising errors or altering buffer state.

---

## 4. Acceptance Criteria (Definition of Done)

### AC-1: Expand Collapsed Directory
* **Given** the cursor is positioned on a collapsed directory node in the SimpleTree buffer,
* **When** the user presses `<CR>` or `<Space>`,
* **Then** the directory's `expanded` state is set to `true`, the buffer is re-rendered to display its child nodes with increased indentation, its icon changes to `FOLDER_ICON_OPEN` (``), and cursor position on that directory is preserved.

### AC-2: Collapse Expanded Directory
* **Given** the cursor is positioned on an expanded directory node in the SimpleTree buffer,
* **When** the user presses `<CR>` or `<Space>`,
* **Then** the directory's `expanded` state is set to `false`, all of its descendant nodes are hidden from the buffer, its icon changes to `FOLDER_ICON_CLOSED` (``), and the cursor remains on the directory line.

### AC-3: Open File on Enter in Right Window
* **Given** the cursor is positioned on a file node in the SimpleTree buffer,
* **When** the user presses `<CR>`,
* **Then** the file is opened in the window to the right of SimpleTree (or a new right vertical split is opened if none exists), and editor focus moves to the opened file window.

### AC-4: File Node Space Invocation (No-Op)
* **Given** the cursor is positioned on a file node in the SimpleTree buffer,
* **When** the user presses `<Space>`,
* **Then** no tree state changes occur, no buffer modification takes place, no file is opened, and no error is thrown.

### AC-5: Deeply Nested Hierarchy Expansion
* **Given** a directory structure with multiple nested levels,
* **When** expanding or collapsing intermediate directories via `<CR>` or `<Space>`,
* **Then** child indentation and sibling nodes maintain their relative visual hierarchy without corruption.
