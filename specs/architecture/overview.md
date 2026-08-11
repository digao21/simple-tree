# Architectural Specification: System Foundation & Global Design Principles

---

## 1. System Overview & Core Philosophy
The architecture of this system is built on the principles of **Maintainability and Strict Decoupling**.
We prioritize explicit contracts over implicit magic, modular boundaries over monolithic coupling, and domain logic purity over framework dependency.

### Core Engineering Tenets
*   **Separation of Concerns:** Business logic must remain entirely independent of UI frameworks, database drivers, and external network protocols.
*   **Encapsulation:** Do not make something public that can be private.
*   **Fail Fast & Gracefully:** Errors must be caught early, handled explicitly, and never swallowed silently.
*   **Determinism:** Side effects must be isolated, bounded, and clearly documented.
*   **Simplicity:** Do not add unnecessary code.

---

## 2. Filesystem structure
*   lua/
    *   simple-tree.lua: implements the setup function responsible to set plugin configuration.
    *   simple-tree/
        *   filesystem.lua: in memory filesystem representation and state.
        *   infrastructure/
            *   filesystem.lua: OS filesystem interaction.
*   plugin/
    *   simple-tree.lua: initializes the plugin, which means
        *   Creating Neovim commands.
        *   Creates Neovim autocommands.
        *   Creates filesystem watchers.

### 2.1 Constrains
* Only the code inside `plugin/` and `lua/infrastructure/` can access vim API.
  `tests/` can only access vim api to test code from the above folders.
  There is no other exception, which means no other file can access vim API.
