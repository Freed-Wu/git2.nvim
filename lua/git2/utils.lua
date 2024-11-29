-- luacheck: ignore 111 113
---@diagnostic disable: undefined-global
local M = {}

---@return string
function M.getcwd()
    if vim then
        return vim.fn.getcwd()
    end
    return require "lfs".currentdir()
end

---@param dir string
---@return boolean
function M.isdirectory(dir)
    if vim then
        return vim.fn.isdirectory(dir) == 1
    end
    return require "lfs".attributes(dir).mode == "directory"
end

---@param dir string
---@param file string
---@return string
function M.joinpath(dir, file)
    if vim then
        return vim.fs.joinpath(dir, file)
    end
    return dir .. "/" .. file
end

---@param dir string
---@return string
function M.dirname(dir)
    if vim then
        return vim.fs.dirname(dir)
    end
    local result, _ = dir:gsub("/[^/]+/?$", "")
    return result
end

---@param dir string
---@return string
function M.get_toplevel(dir)
    while dir ~= "/" do
        if M.isdirectory(M.joinpath(dir, ".git")) then
            return dir
        end
        dir = M.dirname(dir)
    end
    return ""
end

---@param dir string
---@return string
function M.expand(dir)
    if vim then
        return vim.fn.expand(dir)
    end
    return dir
end

return M
