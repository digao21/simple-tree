# Window - Part 1
**Status**: draft

Draft plan to implement `specs/features/window.md`.
Use `specs/architecture` as source of truth.
In case of conflict with this document, `specs/architecture` has precedence.

## Open command

Follow those instructions to implement the open command:

* Get the filesystem information from `infrastructure/filesystem.lua` and saves it as root in `filesystem.lua`.
* Gets the filesystem root from `filesystem.lua` and transforms it into a list of string using ui.lua.
* Opens a window using `infrastructure/window.lua` passing the array of string as the window content.
