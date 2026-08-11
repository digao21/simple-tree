# Conversation Export: Neovim File Explorer Plugin Development

**Date:** 2026-08-10  
**Workspace:** `/home/rodrigolm/git/simple-tree`

---

## 1. Getting Filesystem Information in Neovim

### User Question
> I'll implement a neovim plugin to work as a file tree explorer. How do you suggest me to get the file system information?

### Response

To implement a performant and responsive file tree explorer plugin in Neovim, the best approach depends on your requirements for performance, async execution, and external dependencies.

Here are the recommended ways to get filesystem information in Neovim Lua:

#### 1. Modern Standard: `vim.uv` / `vim.loop` (Recommended)

Neovim embeds **libuv**, accessible via `vim.uv` (Neovim 0.10+) or `vim.loop` (Neovim 0.5–0.9). Popular file tree plugins like `nvim-tree`, `oil.nvim`, and `neo-tree` rely heavily on libuv for high-performance filesystem operations.

##### Fast Synchronous Directory Scanning
`uv.fs_scandir` combined with `uv.fs_scandir_next` is extremely fast because it retrieves the entry name and file type (`file`, `directory`, `link`, etc.) in a single call without needing separate `stat` calls for each entry.

```lua
local uv = vim.uv or vim.loop

local function read_dir(path)
  local entries = {}
  local handle, err = uv.fs_scandir(path)
  
  if not handle then
    vim.notify("Error scanning directory: " .. tostring(err), vim.log.levels.ERROR)
    return entries
  end

  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end

    table.insert(entries, {
      name = name,
      type = type, -- 'file', 'directory', 'link', 'fifo', etc.
      path = path .. "/" .. name,
    })
  end

  return entries
end
```

##### Asynchronous Directory Scanning (Non-blocking UI)
For large directories, running filesystem calls asynchronously keeps the Neovim UI responsive:

```lua
local uv = vim.uv or vim.loop

local function read_dir_async(path, callback)
  uv.fs_scandir(path, function(err, handle)
    if err or not handle then
      vim.schedule(function() callback({}, err) end)
      return
    end

    local entries = {}
    while true do
      local name, type = uv.fs_scandir_next(handle)
      if not name then break end
      table.insert(entries, { name = name, type = type, path = path .. "/" .. name })
    end

    -- Return back to Neovim's main thread to safely update UI/buffers
    vim.schedule(function()
      callback(entries, nil)
    end)
  end)
end
```

##### Getting Detailed Metadata (`uv.fs_stat` / `uv.fs_lstat`)
If you need additional file stats (size, modification time, permissions, or symlink targets):

```lua
local stat, err = uv.fs_stat(filepath)
if stat then
  print("Size:", stat.size, "Bytes")
  print("Permissions (octal):", string.format("%o", stat.mode))
  print("Modified Time:", stat.mtime.sec)
end
```

---

#### 2. High-Level Vimscript API: `vim.fn.readdir`

If you are prototyping or prefer a simpler built-in function without callbacks, Neovim offers `vim.fn.readdir()`.

```lua
-- Simple array of names
local names = vim.fn.readdir("/path/to/dir")

-- Dictionary array containing name and type metadata (Neovim 0.8+)
local entries = vim.fn.readdir("/path/to/dir", nil, { dict = true })
-- returns table of { { name = "foo", type = "file" }, { name = "bar", type = "dir" } }
```

* **Pros:** Simple and concise.
* **Cons:** Synchronous (blocks Neovim thread during slow disk I/O).

---

#### 3. Spawning External Commands: `vim.system` (For `.gitignore` / Fast Search)

If your explorer needs to respect `.gitignore` rules or integrate with Git status, executing `git` or CLI tools like `fd` via `vim.system` (Neovim 0.10+) is effective:

```lua
-- Fetch untracked / modified files using Git
vim.system({ "git", "status", "--porcelain" }, { cwd = root_path }, function(obj)
  if obj.code == 0 then
    vim.schedule(function()
      -- Parse Git status output lines
      print(obj.stdout)
    end)
  end
end)
```

---

#### Summary & Recommendations

| Use Case | Recommended API | Why? |
| :--- | :--- | :--- |
| **Core File Tree Explorer** | `vim.uv.fs_scandir` | Fastest C-level bindings built into Neovim; returns `type` directly. |
| **Non-blocking UI** | Async `vim.uv.fs_scandir` + `vim.schedule` | Prevents freezing Neovim when expanding large folders. |
| **Quick Prototype / Simple Tasks** | `vim.fn.readdir` | Simple one-liner. |
| **Git / Ignore Rules Integration** | `vim.system` with `git` or `fd` | Delegates complex pattern matching to dedicated tools. |

---

## 2. File System Change Notifications (Creation, Deletion, Updates)

### User Question
> How to be nitified if a file/directory was created, deleted or updated?

### Response

To be notified of file and directory creations, deletions, or updates in real time, you can use Neovim's built-in **`vim.uv.new_fs_event()`** (libuv filesystem events). 

This uses native OS APIs under the hood (`inotify` on Linux, `FSEvents` on macOS, and `ReadDirectoryChangesW` on Windows).

---

#### 1. Primary Method: `vim.uv.new_fs_event()`

`new_fs_event` watches a specific directory or file for changes.

##### Example: Watching a Directory for Changes

```lua
local uv = vim.uv or vim.loop

local function watch_directory(dir_path, on_change_callback)
  -- 1. Create a watcher instance
  local watcher = uv.new_fs_event()

  if not watcher then
    vim.notify("Failed to create fs_event watcher", vim.log.levels.ERROR)
    return nil
  end

  -- 2. Start watching
  -- Flags: { watch_entry = false, stat = false, recursive = true }
  watcher:start(dir_path, { recursive = true }, function(err, filename, events)
    if err then
      vim.schedule(function()
        vim.notify("FS Event Error: " .. tostring(err), vim.log.levels.ERROR)
      end)
      return
    end

    -- events is a table: { change = boolean, rename = boolean }
    -- 'rename' fires on creation, deletion, or renaming.
    -- 'change' fires on file modifications (writes).

    local change_type = "updated"
    if events.rename then
      -- Check if file exists to distinguish creation/rename from deletion
      local full_path = dir_path .. "/" .. (filename or "")
      local stat = uv.fs_stat(full_path)
      if stat then
        change_type = "created/renamed"
      else
        change_type = "deleted"
      end
    elseif events.change then
      change_type = "modified"
    end

    -- CRITICAL: Always use vim.schedule when updating Neovim UI or buffers
    vim.schedule(function()
      on_change_callback(filename, change_type, events)
    end)
  end)

  return watcher
end

-- --- Usage ---
local my_watcher = watch_directory("/path/to/my/project", function(filename, change_type, events)
  print(string.format("File '%s' was %s", filename, change_type))
  -- Here you can trigger your tree redraw or update state
end)

-- To stop watching later:
-- if my_watcher then my_watcher:stop() end
```

---

#### Key Concepts & Events

| Event Flag | Meaning | How to determine action |
| :--- | :--- | :--- |
| `events.rename = true` | File **Created**, **Deleted**, or **Renamed** | Run `uv.fs_stat(filepath)`:<br>• If stat exists $\rightarrow$ **Created** or **Renamed**<br>• If stat is `nil` $\rightarrow$ **Deleted** |
| `events.change = true` | File **Modified** | File contents or stat attributes updated |

---

#### Important Caveats for File Tree Plugins

1. **Thread Safety (`vim.schedule`)**: The watcher callback executes on the libuv event loop thread. You **must** wrap any Neovim API calls (`vim.api.*`, redrawing buffers, opening windows) inside `vim.schedule(function() ... end)`.
2. **Debouncing Updates**: File changes often fire multiple rapid events (e.g. text editors writing to temporary files then swapping them). It is best practice to **debounce** your tree refresh by 50–100ms so you don't re-scan the directory 10 times in a fraction of a second.
3. **Recursive Watching on Linux**: While `recursive = true` works out of the box on macOS and Windows, libuv on Linux (`inotify`) does not natively support recursive directory watching across newly created subdirectories without adding watchers to each subdirectory. Most tree plugins attach a watcher handle to every **expanded folder** in the tree.

---

#### 2. Complementary Method: Neovim Autocmds

In addition to disk watchers, you should listen to Neovim buffer events so your tree instantly syncs when files are created or saved *inside* Neovim:

```lua
local group = vim.api.nvim_create_augroup("FileTreeWatcher", { clear = true })

-- Trigger when user saves a file inside Neovim
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  callback = function(args)
    -- Refresh tree if saved file is inside project root
  end,
})

-- Trigger when Neovim regains focus (user changed files outside in terminal/git)
vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  callback = function()
    -- Refresh tree state
  end,
})
```

---

## 3. Manipulating and Editing Buffers for a File Explorer

### User Question
> I'm writing a file explorer plugin for neovim. What is the best way to manipulate the buffer to write and edit the file explorer?

### Response

When building a File Explorer plugin in Neovim, the best approach depends on which of the **two main architecture patterns** you choose to follow:

1. **Read-Only / Tree View (like `nvim-tree` or `neo-tree`)**: The buffer is read-only (`modifiable = false`). Keymaps like `<CR>` (open/expand), `a` (create), `d` (delete), or `r` (rename) trigger Lua callbacks that update the filesystem and re-render buffer lines programmatically.
2. **Editable Buffer (like `oil.nvim` or `dirvish`)**: The buffer is editable (`modifiable = true`). Users edit filenames directly in Vim normal/insert mode, and a `BufWriteCmd` autocommand catches `:w` to diff buffer contents against the filesystem and execute batch file operations.

---

### 1. Setting Up the Explorer Buffer & Window Options

Regardless of design, create a dedicated scratch buffer and set strict buffer-local options.

```lua
local function create_explorer_buffer()
  -- Create a new unlisted scratch buffer
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.bo[bufnr].buftype = "nofile"      -- Not associated with a real file on disk directly
  vim.bo[bufnr].bufhidden = "wipe"      -- Wipe out when hidden/closed
  vim.bo[bufnr].swapfile = false        -- Disable swap file
  vim.bo[bufnr].filetype = "simple-tree" -- For custom ftplugin / syntax rules

  return bufnr
end
```

---

### 2. Pattern A: Read-Only Tree View (Programmatic Buffer Manipulation)

To manipulate a read-only buffer safely:

1. Temporarily unlock `modifiable = true`.
2. Write lines using `vim.api.nvim_buf_set_lines()`.
3. Lock `modifiable = false` immediately after.

#### Writing & Incremental Line Updates

Use `vim.api.nvim_buf_set_lines` to insert, update, or remove lines:

```lua
local function render_tree(bufnr, lines)
  -- 1. Unlock buffer
  vim.bo[bufnr].modifiable = true

  -- 2. Replace lines (0, -1 replaces the entire buffer)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- 3. Lock buffer again
  vim.bo[bufnr].modifiable = false
end
```

> **Tip for Collapsing/Expanding Nodes**: Rather than redrawing the whole buffer, replace only the range of lines corresponding to the expanded/collapsed directory:
> ```lua
> -- Replace lines 5 to 12 with new child nodes
> vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, new_lines)
> ```

#### Line-to-Node Mapping

Maintain a Lua table or use Extmarks to map buffer line numbers (1-indexed) back to your filesystem nodes:

```lua
-- Buffer line -> Node data structure
local line_map = {} 

local function render_nodes(bufnr, nodes)
  local lines = {}
  line_map = {}

  for idx, node in ipairs(nodes) do
    local indent = string.rep("  ", node.depth or 0)
    local icon = node.type == "directory" and "📁 " or "📄 "
    table.insert(lines, indent .. icon .. node.name)
    line_map[idx] = node
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

-- Retrieve node under cursor
local function get_current_node()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  return line_map[cursor_line]
end
```

---

### 3. Highlights & Virtual Text using Extmarks

Use Neovim's Extmark API (`vim.api.nvim_buf_set_extmark`) to render icons, custom colors, or git status indicators without altering the raw text of the buffer.

```lua
local ns_id = vim.api.nvim_create_namespace("simple_tree_ui")

local function highlight_line(bufnr, line_idx, node)
  -- Extmark lines are 0-indexed
  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx - 1, 0, {
    line_hl_group = node.type == "directory" and "Directory" or "Normal",
    -- Example: Add inline virtual text (e.g. git status or file permissions)
    virt_text = { { node.type == "directory" and " [dir]" or "", "Comment" } },
    virt_text_pos = "eol",
  })
end
```

---

### 4. Pattern B: Editable Buffer (Oil.nvim style)

If you want users to edit filenames like regular text lines:

1. Keep `modifiable = true`.
2. Intercept buffer save (`:w`) using `BufWriteCmd`.
3. Parse new buffer lines, compare them with initial directory state, and execute `fs.rename`, `fs.unlink`, or `fs.mkdir`.

```lua
local function setup_editable_explorer(bufnr, dir_path)
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = function()
      local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      
      -- Compare new_lines with initial directory entries:
      -- 1. Removed lines -> Delete file (uv.fs_unlink)
      -- 2. Changed lines  -> Rename file (uv.fs_rename)
      -- 3. Added lines    -> Create file (uv.fs_open / uv.fs_mkdir)

      -- Mark buffer as clean (saved)
      vim.bo[bufnr].modified = false
    end,
  })
end
```

---

### Summary of Recommended Best Practices

| Task | Recommended Neovim API |
| :--- | :--- |
| **Write/Update Buffer Lines** | `vim.api.nvim_buf_set_lines(bufnr, start, end, false, lines)` |
| **Read Buffer Lines** | `vim.api.nvim_buf_get_lines(bufnr, start, end, false)` |
| **Toggle Edit Ability** | `vim.bo[bufnr].modifiable = true / false` |
| **Line Metadata / Icons / Colors** | `vim.api.nvim_buf_set_extmark` with `vim.api.nvim_create_namespace` |
| **Buffer-Local Actions** | `vim.keymap.set('n', '<CR>', callback, { buffer = bufnr })` |

---

## 4. Pattern A: Tree State & Node-to-Line Mapping Synchronization

### User Question
> Let's focus on pattern A. If I open/close a folder, should I rewrite everything or there is a data structure I can use to keep the node to line map in synchronization?

### Response

#### 1. Should you rewrite everything on open/close?

**Yes, for most file explorers, re-rendering the visible tree is the standard, cleanest, and fastest approach.** 

In Lua + Neovim C-APIs, calling `vim.api.nvim_buf_set_lines()` on a buffer of 100 to 2,000 visible lines takes less than **1 millisecond**. Redrawing the visible tree avoids edge-case synchronization bugs (such as lines getting out of order when collapsing multi-level nested folders).

However, you still need a data structure to map **line numbers $\leftrightarrow$ tree nodes** when the user moves their cursor around.

Here are the **two best strategies** to manage this data structure.

---

#### Strategy 1: The "Flattened Visible List" Pattern (Recommended)

In this pattern, your canonical data structure is your **Tree graph** (e.g. your `Node` struct from `filesystem.lua`). You add an `is_expanded` boolean flag to directory nodes.

Whenever a node is opened or closed, you **flatten** only the currently visible nodes into a flat 1D array (`visible_nodes`).

##### How it works:

```
Tree State (In Memory)                     Flat Visible List (Buffer Lines)
----------------------                     --------------------------------
root (expanded)                            Line 1: 📁 root
 ├── src (expanded)            DFS         Line 2:   📁 src
 │    ├── main.lua           ──────>       Line 3:     📄 main.lua
 │    └── utils.lua                        Line 4:     📄 utils.lua
 └── README.md                             Line 5:   📄 README.md
```

##### Code Implementation:

```lua
-- 1. Tree Node Definition
---@class TreeUI
---@field root Node
---@field visible_nodes Node[]
local TreeUI = {}
TreeUI.__index = TreeUI

function TreeUI.new(root_node)
  return setmetatable({
    root = root_node,
    visible_nodes = {},
  }, TreeUI)
end

-- 2. Flatten Tree via Depth-First Search (DFS)
function TreeUI:rebuild_visible_nodes()
  self.visible_nodes = {}

  local function traverse(node, depth)
    node.depth = depth
    table.insert(self.visible_nodes, node)

    -- Only traverse children if directory is expanded
    if node.type == "directory" and node.is_expanded and node.childs then
      for _, child in ipairs(node.childs) do
        traverse(child, depth + 1)
      end
    end
  end

  traverse(self.root, 0)
end

-- 3. Render Buffer & Synchronize
function TreeUI:render(bufnr)
  self:rebuild_visible_nodes()

  local lines = {}
  for _, node in ipairs(self.visible_nodes) do
    local indent = string.rep("  ", node.depth)
    local icon = node.type == "directory" and (node.is_expanded and "📂 " or "📁 ") or "📄 "
    table.insert(lines, indent .. icon .. node.name)
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

-- 4. Instant O(1) Lookup for Node under Cursor
function TreeUI:get_node_at_cursor(win_id)
  local cursor_line = vim.api.nvim_win_get_cursor(win_id or 0)[1]
  return self.visible_nodes[cursor_line] -- Line 1 maps to index 1!
end
```

##### Why this is great:
- **Zero index math**: Line 5 in Neovim buffer is `visible_nodes[5]`.
- **Simplest state management**: You toggle `node.is_expanded = not node.is_expanded`, call `:render()`, and everything stays 100% in sync.

---

#### Strategy 2: Neovim Extmarks (Native Automatic Tracking)

If you prefer **partial buffer updates** (inserting/removing only the new lines when expanding a folder without redrawing the whole buffer), traditional array indexing breaks because inserting 5 lines shifts all line numbers below down by +5.

Neovim provides a native feature for this: **Extmarks** (`vim.api.nvim_buf_set_extmark`).

##### How Extmarks work:
When you attach an extmark to line $L$, **Neovim automatically tracks and shifts the extmark's line position** when lines are added or removed above it.

```
Initial State:
Line 1: 📁 root   ---> Extmark #101 (Node: root)
Line 2: 📄 README ---> Extmark #102 (Node: README)

User expands "root" (Inserts 2 child lines at line 2):
Line 1: 📁 root   ---> Extmark #101 (Line 1)
Line 2:   📄 a.lua ---> Extmark #103 (Line 2) [NEW]
Line 3:   📄 b.lua ---> Extmark #104 (Line 3) [NEW]
Line 4: 📄 README ---> Extmark #102 (Automatically shifted to Line 4 by Neovim!)
```

##### Code Implementation:

```lua
local ns_id = vim.api.nvim_create_namespace("simple_tree_extmarks")

-- Lookup table: extmark_id -> Node
local extmark_to_node = {}

-- Add a node line with an extmark
local function draw_node_line(bufnr, line_idx, node, text)
  vim.api.nvim_buf_set_lines(bufnr, line_idx, line_idx, false, { text })

  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx, 0, {
    -- Key setting: gravity/tracking options
    right_gravity = false,
  })

  extmark_to_node[mark_id] = node
  node.extmark_id = mark_id
end

-- Get node under cursor using Extmark query
local function get_node_at_cursor(bufnr)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed line

  -- Get extmark at cursor line
  local marks = vim.api.nvim_buf_get_extmarks(
    bufnr, ns_id,
    { line, 0 },
    { line, -1 },
    { details = false }
  )

  if #marks > 0 then
    local mark_id = marks[1][1]
    return extmark_to_node[mark_id]
  end
  return nil
end
```

---

#### Strategy Comparison

| Criteria | Strategy 1: Flattened Visible List | Strategy 2: Extmarks + Partial Updates |
| :--- | :--- | :--- |
| **Complexity** | 🟢 **Very Low** (Single `is_expanded` flag + DFS) | 🟡 **Medium** (Requires Extmark lifecycle management) |
| **Performance** | 🟢 **Instant** (<1ms for <5,000 visible lines) | 🟢 **Instant** (Saves minor sub-millisecond draw time) |
| **Bug Likelihood** | 🟢 **Near Zero** (Buffer state always reflects tree state) | 🟡 **Possible** (Extmark cleanup needed when deleting lines) |
| **Used By** | `nvim-tree`, `neo-tree` | Complex custom line trackers |

---
