# Architectural Specification: System Topology & Component Design Principles

**Status:** Approved  
**Architecture Pattern:** Ports and Adapters (Hexagonal Architecture)  
**Target Environment:** NeoVim v0.11.5+ (Lua 5.1 / LuaJIT 2.1)

---

## 1. Architectural Overview & System Philosophy

The `simple-tree` system is architected around the **Ports and Adapters (Hexagonal Architecture)** design pattern. The core objective is **total decoupling** of core filesystem domain logic from Neovim engine APIs (`vim.api`, `vim.fn`, `vim.uv`, `vim.bo`, `vim.wo`).

### 1.1 Core Engineering Tenets

1. **Strict Boundary Isolation:** Domain logic must have zero knowledge of Neovim API contracts. It operates strictly on plain Lua tables, strings, booleans, and functions.
2. **Encapsulation, Immutability & Observer Pattern:** The `model` module is responsible for the plugin domain model and internal state control. Internal state mutations are restricted to `model/filesystem.lua`, and all external access is performed through `model/init.lua`. The `model/init.lua` facade implements the **Observer Pattern** (`subscribe`, `unsubscribe`), notifying registered subscribers whenever the domain model mutates (e.g. active root updates, directory expansion toggling). Exposed states must return deep copies via [`util.deepCopy`](file:///home/rodrigolm/git/simple-tree/lua/simple-tree/util.lua#L6-L26) to prevent external reference leaks.
3. **Fail-Fast & Deterministic Execution:** Side effects (file IO, buffer writes) are isolated inside infrastructure modules. Functions in domain modules must be deterministic and pure.
4. **Asynchronous Non-Blocking IO:** Filesystem traversal is performed asynchronously over Neovim's `libuv` event loop (`vim.uv.fs_scandir`), guaranteeing zero UI main-thread blocking.

---

## 2. System Topology & Component Responsibilities

```
simple-tree/
├── lua/
│   ├── simple-tree.lua                   # Plugin configuration setup entrypoint
│   └── simple-tree/
│       ├── command.lua                   # Pure domain command dispatcher & parser
│       ├── model/                        # Plugin domain model & internal state control
│       │   ├── init.lua                  # Model public facade & Observer dispatcher (subscribe/notify)
│       │   └── filesystem.lua            # In-memory filesystem tree state store
│       ├── ui.lua                        # Transforms internal state into a presentational model
│       ├── util.lua                      # Utility functions
│       └── infrastructure/
│           ├── filesystem.lua            # Async libuv OS directory scanner (Vim API boundary)
│           └── window.lua                # Neovim window/buffer driver (Vim API boundary)
├── plugin/
│   └── simple-tree.lua                   # Plugin bootstrapper & Vim command installer
├── specs/                                # Technical specifications and ADRs
└── tests/                                # Busted unit & integration test suites
```

## 3. Strict Boundary Constraints (Vim API Isolation)

To preserve long-term maintainability and testability, the system enforces a strict API access rule:

> [!IMPORTANT]
> **The `vim` global object (`vim.api`, `vim.fn`, `vim.uv`, `vim.bo`, `vim.wo`, etc.) is strictly forbidden inside core domain modules (`lua/simple-tree/*.lua`).**  
> Direct access to `vim` is permitted **ONLY** within:
> 1. `plugin/**/*.lua`
> 2. `lua/simple-tree/infrastructure/**/*.lua`
> 3. `tests/**/*.lua` (restricted to testing infrastructure adapters).

---

## 4. Testing Strategy

1. **Pure Unit Testing (Domain Layer):**
   * Domain modules (`model`, `ui.lua`, `util.lua`, `command.lua`) are tested in isolation using Busted without instantiating Neovim windows or mocks. Observer subscription and notification behaviors are verified through unit tests.
2. **Integration Testing (Infrastructure Layer):**
   * Infrastructure adapters (`infrastructure/filesystem.lua`, `infrastructure/window.lua`) are tested within an embedded Neovim runtime (`nlua`), verifying actual buffer states, window flags, and async filesystem callbacks.
