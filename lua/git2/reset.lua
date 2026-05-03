---git reset
local git2 = require "git2"
local M = {}

---git reset
---@param repo userdata
---@param idx userdata
---@param file string
function M.reset(repo, idx, file)
    local commit = git2.Object.revparse_single(repo, "HEAD")
    local tree = commit:tree()
    local e = git2.TreeEntry.bypath(tree, file)
    local entry = git2.IndexEntry()
    entry:set_id(e:id())
    entry:set_mode(e:filemode())
    entry:set_path(file)
    idx:add(entry)
end

---for fern
---@param file string
function M.unstage(file)
    local fs = require "vim.fs"
    local fn = require "vim.fn"
    local git_dir = fs.root(fn.getcwd(), '.git')
    local repo = git2.Repository.open(git_dir)
    if repo == nil then
        return
    end
    local idx = repo:index()
    M.reset(repo, idx, file)
    idx:write()
end

---for fern
---@param file string
function M.stage(file)
    local fs = require "vim.fs"
    local fn = require "vim.fn"
    local git_dir = fs.root(fn.getcwd(), '.git')
    local repo = git2.Repository.open(git_dir)
    if repo == nil then
        return
    end
    local idx = repo:index()
    local arr = git2.StrArray(1)
    file = fs.relpath(git_dir, file)
    if file then
        arr:set_str(0, file)
        idx:add_all(arr, 0)
        idx:write()
    end
end

return M
