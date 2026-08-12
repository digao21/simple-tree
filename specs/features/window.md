# Feature Specification: Filesystem window
**Status:** Approved

---

## 1. Objective and Scope
*   **Objective:** Create commands to open and close the simple-tree window and shows the filesystem.

---

## 2. Technical Stack and Dependencies
*   **Language/Runtime:** Lua 5.1, NeoVim v0.11.5, LuaJIT 2.1

---

## 3. Requirements

### 3.1 Commands

Create three commands:
    * `SimpleTree open`: opens the simple-tree window and shows the filesystem.
    * `SimpleTree close`: closes the simple-tree window.
    * `SimpleTree toggle`: if the window is open closes it, otherwise opens it.

### 3.2 Window Specification

* The window must be readonly.
* The window must be exclusive from the file system buffer (no other buffer must open this window).
* The tree filetype must be "simple-tree" for further extensions.

Optimize for resource usage and security.
