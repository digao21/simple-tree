# Feature Specification: Tree Navigation & Directory Expansion

**Status:** Approved  
**Feature:** SimpleTree Navigation & Node Expansion  
**Target:** Buffer keymaps and tree expansion lifecycle

---

## 1. Feature Summary & Objective

Provide buffer-local keymaps and domain actions to toggle (expand/collapse) directory nodes within the SimpleTree explorer window. Expanding a directory reveals its child files and subdirectories, while collapsing a directory hides its descendants, updating the visual tree state and folder icon representation.

---

## 2. Keybinding Interface

Inside the `simple-tree` filetype buffer, the following default buffer-local keybindings are available:

| Keymap | Action | Target Node Type | Description |
| :--- | :--- | :--- | :--- |
| `<CR>` | Toggle Expansion | Directory | Expands the directory if collapsed; collapses it if expanded. |
| `<Space>` | Toggle Expansion | Directory | Expands the directory if collapsed; collapses it if expanded. |

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

### 3.3 Non-Directory (File) Node Handling
* Invoking toggle expansion actions on a file node (`type == "file"`) performs a graceful no-op without raising errors or altering buffer state.

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

### AC-3: File Node Invocation (No-Op)
* **Given** the cursor is positioned on a file node in the SimpleTree buffer,
* **When** the user presses `<CR>` or `<Space>`,
* **Then** no tree state changes occur, no buffer modification takes place, and no error is thrown.

### AC-4: Deeply Nested Hierarchy Expansion
* **Given** a directory structure with multiple nested levels,
* **When** expanding or collapsing intermediate directories via `<CR>` or `<Space>`,
* **Then** child indentation and sibling nodes maintain their relative visual hierarchy without corruption.
