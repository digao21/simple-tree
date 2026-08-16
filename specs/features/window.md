# Feature Specification: Filesystem Window Management

**Status:** Approved  
**Feature:** SimpleTree Window Management  
**Target:** User-facing window and buffer lifecycle

---

## 1. Feature Summary & Objective

Provide commands to open, close, and toggle a dedicated filesystem explorer sidebar window in Neovim. The window displays the workspace filesystem structure in a read-only, pinned split view without interfering with user editing buffers.

---

## 2. Command Interface

The plugin exposes the `:SimpleTree` command with three sub-commands:

| Sub-command | User Intent | Expected Behavior |
| :--- | :--- | :--- |
| `:SimpleTree open` | Open Explorer | Opens the explorer sidebar window if closed. If already open, shifts focus to the explorer window. |
| `:SimpleTree close` | Close Explorer | Closes the explorer sidebar window if open. If already closed, performs a graceful no-op. |
| `:SimpleTree toggle` | Toggle Explorer | Toggles the window state: closes the explorer if open and focused/visible; otherwise opens it. |

---

## 3. Functional Requirements

### 3.1 Buffer Characteristics
* **Unlisted Scratch Buffer:** Must not appear in user buffer lists (`:ls` / `:bnext`).
* **Non-File Type (`buftype="nofile"`):** Unassociated with disk files; never prompts to save changes.
* **Wipe On Close (`bufhidden="wipe"`):** Automatically destroyed upon window closure to prevent memory leaks.
* **No Swapfile (`swapfile=false`):** Swapfile generation disabled.
* **Dedicated Filetype (`filetype="simple-tree"`):** Custom filetype set for syntax highlighting and ftplugin extensions.
* **Read-Only Protection (`modifiable=false`):** Buffer text cannot be edited directly by the user.

### 3.2 Window & Layout Characteristics
* **Sidebar Placement:** Opened as a vertical split anchored to the far left of the workspace.
* **Buffer Pinning (`winfixbuf=true`):** Prevents standard buffer navigation commands (`:edit`, `:bnext`, `:bprevious`) from opening inside the explorer split.
* **Width Preservation (`winfixwidth=true`):** Maintains fixed width when other splits open or close.
* **Cursorline Highlighting (`cursorline=true`):** Highlights the entire screen line of the cursor to provide clear visual feedback during tree navigation.
* **Gutter Suppression:** Line numbers, relative numbers, sign columns, and fold columns are disabled.

---

## 4. Acceptance Criteria (Definition of Done)

### AC-1: Open Window (Closed State)
* **Given** the SimpleTree window is closed,
* **When** the user executes `:SimpleTree open`,
* **Then** a dedicated left-aligned split window opens, displaying the root directory filesystem tree, with the cursor focused inside the tree window.

### AC-2: Open Window (Already Open State)
* **Given** the SimpleTree window is already open in another split,
* **When** the user executes `:SimpleTree open` from an edit buffer,
* **Then** no new window is created, and input focus moves directly to the existing SimpleTree window.

### AC-3: Close Window (Open State)
* **Given** the SimpleTree window is open,
* **When** the user executes `:SimpleTree close`,
* **Then** the SimpleTree window is closed, its underlying scratch buffer is wiped, and input focus returns to the previously active window.

### AC-4: Close Window (Already Closed State)
* **Given** the SimpleTree window is closed,
* **When** the user executes `:SimpleTree close`,
* **Then** no action is taken, no error is thrown, and the command completes silently.

### AC-5: Toggle Window
* **Given** the SimpleTree window state (open vs closed),
* **When** the user executes `:SimpleTree toggle`,
* **Then** the window state flips (closes if currently open/visible, opens if currently closed).

### AC-6: Read-Only & Buffer Pinning Enforcements
* **Given** the SimpleTree window is open,
* **When** the user attempts to type in the buffer or run `:edit <file>`,
* **Then** text edits are blocked by read-only protection, and buffer changes within the split window are rejected.

### AC-7: Cursorline Highlighting
* **Given** the SimpleTree window is open,
* **When** window configuration options are queried,
* **Then** `cursorline` is enabled (`cursorline=true`) on the window.
