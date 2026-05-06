---git diff
local fs = require 'vim.fs'
local fn = require 'vim.fn'
local git2 = require 'git2'
local M = {}

---for `airline#extensions#hunks#get_raw_hunks()`
---@param root string?
---@param file string?
---@return integer
---@return integer
---@return integer
function M.get_raw_hunks(root, file)
    file = file or fn.expand('%:p')
    root = root or fs.dirname(file)
    local repo_dir = fs.root(root, '.git')
    file = fs.relpath(repo_dir, file)
    local repo = git2.Repository.open(repo_dir)
    if repo == nil then
        return 0, 0, 0
    end
    local idx = repo:index()
    local opts = git2.DiffOptions.init()
    local arr = git2.StrArray(1)
    arr:set_str(0, file)
    opts:set_pathspec(arr)
    local diff = git2.Diff.index_to_workdir(repo, idx, opts)
    local stats = git2.DiffStats.get(diff)
    local i = stats:insertions()
    local d = stats:deletions()
    local c = 0
    return i - c, c, d - c
end

return M
