local filesystem = require("simple-tree.model.filesystem")

local M = {}

M.setRoot = filesystem.setRoot
M.getRoot = filesystem.getRoot
M.getNodeById = filesystem.getNodeById
M.toggleFolder = filesystem.toggleFolder

return M
