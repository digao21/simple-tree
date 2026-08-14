# Feature Specification: Filesystem CRUD Operations

**Status:** Draft  
**Feature:** SimpleTree Filesystem Operations  
**Target:** Buffer keymaps, user input prompts, OS file mutations, and tree state synchronization

---

## 1. Feature Summary & Objective

Provide interactive commands and buffer-local keybindings within the SimpleTree window to perform common filesystem mutations: creating files, creating directories, renaming nodes, and deleting files/directories. Operations must execute asynchronously via libuv, prompt the user for confirmation when destructive, validate input paths, and automatically synchronize the in-memory tree and visual display.

---

## 2. Keybinding & Command Interface

Inside the `simple-tree` filetype buffer, the following default buffer-local keybindings are proposed:

| Keymap | Action | Prompt / Interaction | Description |
| :--- | :--- | :--- | :--- |
| `a` | Create File | `vim.ui.input`: "Create file: " | Creates a new file under the target directory. |
| `A` | Create Directory | `vim.ui.input`: "Create directory: " | Creates a new directory under the target directory. |
| `r` | Rename Node | `vim.ui.input`: "Rename to: <current_name>" | Renames the file or directory under the cursor. |
| `d` | Delete Node | `vim.ui.input` / confirmation: "Delete <name>? (y/n)" | Deletes the file or directory (recursively for folders). |

---

## 3. Functional Requirements

### 3.1 Target Path Resolution
* **Directory Cursor Target:** When the cursor is on a directory node, newly created files or directories are created directly inside that directory.
* **File Cursor Target:** When the cursor is on a file node, new files or directories are created in the parent directory of that file.
* **Nested Path Support:** If the user enters a path with subdirectories (e.g. `foo/bar/baz.lua`), intermediate directories are created automatically (`mkdir -p` semantics).

### 3.2 Input Validation & Sanitization
* **Empty Input:** Submitting an empty string cancels the operation gracefully without error.
* **Special Characters & Bounds:** Invalid characters, trailing slashes, and redundant separators are normalized.
* **Duplicate Detection:** If a destination file or directory already exists during creation or rename, the operation fails safely with an informative error message.

### 3.3 Asynchronous Non-Blocking Execution
* All disk mutations (`fs_open`, `fs_mkdir`, `fs_rename`, `fs_unlink`, `fs_rmdir`) must execute asynchronously through the infrastructure adapter (`infrastructure/filesystem.lua`) over Neovim's `libuv` loop.
* Main UI thread must not block during disk operations.

### 3.4 Destructive Operation Safeguards
* Deleting files or directories requires explicit user confirmation before executing.
* Directory deletion removes contents recursively or prompts for confirmation on non-empty directories.

### 3.5 State Synchronization & UI Refresh
* Upon successful disk mutation, the in-memory tree state (`filesystem.lua`) is updated (or rescanned asynchronously) and the scratch buffer is re-rendered via `ui.renderTree`.
* The cursor is placed on the newly created or renamed node.

---

## 4. Acceptance Criteria (Definition of Done)

### AC-1: Create New File
* **Given** the cursor is positioned on a directory or file in the SimpleTree buffer,
* **When** the user presses `a` and enters a valid filename `utils.lua`,
* **Then** the file is created on disk, the in-memory tree is updated, the buffer re-renders displaying `utils.lua`, and the cursor moves to the new file.

### AC-2: Create New Directory
* **Given** the cursor is positioned in the SimpleTree buffer,
* **When** the user presses `A` and enters a directory name `components`,
* **Then** the directory is created on disk and displayed in the explorer view.

### AC-3: Rename File or Directory
* **Given** the cursor is positioned on an existing node `old_name.lua`,
* **When** the user presses `r`, edits the name to `new_name.lua`, and confirms,
* **Then** the filesystem item is renamed on disk, the tree view updates, and cursor focus stays on the renamed node.

### AC-4: Delete Node with Confirmation
* **Given** the cursor is positioned on a node `temp.txt`,
* **When** the user presses `d` and confirms deletion with `y`,
* **Then** the item is removed from disk and from the SimpleTree buffer.

### AC-5: Cancellation
* **Given** any operation prompt is open (`a`, `A`, `r`, `d`),
* **When** the user cancels (e.g. presses `<Esc>` or submits empty input),
* **Then** no disk changes occur, the buffer remains unchanged, and the prompt dismisses cleanly.

### AC-6: IO Error Handling
* **Given** an IO error occurs (e.g. permission denied or read-only filesystem),
* **When** the operation fails,
* **Then** an error notification is surfaced to the user without crashing the plugin or corrupting buffer state.
