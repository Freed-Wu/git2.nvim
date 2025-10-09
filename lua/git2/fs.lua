---wrap `vim.fs` and `vim.fn`
-- luacheck: ignore 111 113
local lfs = require "lfs"
local M = {}

---wrap `vim.fs.dir()`
---@param path string
---@return function
function M.dir(path)
    if vim then
        return vim.fs.dir(path)
    end
    return lfs.dir(path)
end

---wrap `vim.fs.relpath()`
---@param base string
---@param target string
---@return string path
function M.relpath(base, target)
    if vim then
        return vim.fs.relpath(base, target)
    end
    local path = target:gsub("/%./", "/")
    while path:match("/%.%./") do
        path = path:gsub("/[^/]+/%.%./", "/", 1)
    end
    local pat = base:gsub("%-", "%%-")
    path = path:gsub(pat .. "/", "")
    return path
end

---wrap `vim.fs.root()`
---@param source string
---@param marker string
---@return string
function M.root(source, marker)
    if vim then
        return vim.fs.root(source, marker)
    end
    while source ~= "/" do
        if M.isdirectory(M.joinpath(source, marker)) then
            return source
        end
        source = M.dirname(source)
    end
    return ""
end

---wrap `vim.fs.joinpath()`
---@param ... string
---@return string
function M.joinpath(...)
    if vim then
        return vim.fs.joinpath(...)
    end
    return table.concat({...}, '/')
end

---wrap `vim.fs.dirname()`
---@param path string
---@return string
function M.dirname(path)
    if vim then
        return vim.fs.dirname(path)
    end
    return path:match("(.*)/[^/]*$") or '/'
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

---wrap `vim.fn.filereadable()`
---@param dir string
---@return boolean isdir
function M.filereadable(dir)
    if vim then
        return vim.fn.filereadable(dir) == 1
    end
    return lfs.attributes(dir) and lfs.attributes(dir).mode == "file"
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
