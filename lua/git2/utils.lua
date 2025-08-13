---wrap `vim.fs` and `vim.fn`
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 113
local lfs = require "lfs"
local M = {}

---wrap `vim.fn.getcwd()`
---@return string cwd
function M.getcwd()
    if vim then
        return vim.fn.getcwd()
    end
    return lfs.currentdir()
end

---wrap `vim.fn.isdirectory()`
---@param dir string
---@return boolean isdir
function M.isdirectory(dir)
    if vim then
        return vim.fn.isdirectory(dir) == 1
    end
    return lfs.attributes(dir) and lfs.attributes(dir).mode == "directory"
end

---wrap `vim.fs.joinpath()`
---@param dir string
---@param file string
---@return string
function M.joinpath(dir, file)
    if vim then
        return vim.fs.joinpath(dir, file)
    end
    return dir .. "/" .. file
end

---wrap `vim.fs.dirname()`
---@param path string
---@return string
function M.dirname(path)
    if vim then
        return vim.fs.dirname(path)
    end
    return path:match("(.*)/[^/]*$")
end

---wrap `vim.fs.basename()`
---@param path string
---@return string
function M.basename(path)
    if vim then
        return vim.fs.basename(path)
    end
    return path:match("/([^/]*)$")
end

---wrap `vim.fn.expand()`
---@param dir string
---@return string
function M.expand(dir)
    if vim then
        return vim.fn.expand(dir)
    end
    return dir
end

return M
