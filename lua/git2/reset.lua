---git reset
local fs = require "vim.fs"
local git2 = require "git2"
local M = {}

---git reset
---@param repo userdata
---@param file string
---@return userdata
function M.get_index_entry(repo, file)
    local commit = git2.Object.revparse_single(repo, "HEAD")
    local tree = commit:tree()
    local e = git2.TreeEntry.bypath(tree, file)
    local entry = git2.IndexEntry()
    entry:set_id(e:id())
    entry:set_mode(e:filemode())
    entry:set_path(file)
    return entry
end

---git add
---@param git_dir string
---@param files string[]
function M.get_str_array(git_dir, files)
    local arr = git2.StrArray(#files)
    for i, file in ipairs(files) do
        file = fs.relpath(git_dir, file)
        -- c index from 0
        if file then
            arr:set_str(i - 1, file)
        end
    end
    return arr
end

---for fern
---@param root string
---@param files string[]
function M.unstage(root, files)
    local git_dir = fs.root(root, '.git')
    local repo = git2.Repository.open(git_dir)
    if repo == nil then
        return
    end
    local idx = repo:index()
    for _, file in ipairs(files) do
        file = fs.relpath(git_dir, file)
        local entry = M.get_index_entry(repo, file)
        idx:add(entry)
    end
    idx:write()
end

---for fern
---@param root string
---@param files string[]
function M.stage(root, files)
    local git_dir = fs.root(root, '.git')
    local repo = git2.Repository.open(git_dir)
    if repo == nil then
        return
    end
    local idx = repo:index()
    local arr = M.get_str_array(git_dir, files)
    idx:add_all(arr, 0)
    idx:write()
end

return M
