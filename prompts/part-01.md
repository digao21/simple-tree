# Conversation Export: Neovim File Explorer Plugin Development

**Date:** 2026-08-08  
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
