local bit = require "bit"
local git2 = require "git2"

local M = {
    statuses = {
        CURRENT = 0,
        INDEX_NEW = 1,
        INDEX_MODIFIED = 2,
        INDEX_DELETED = 4,
        INDEX_RENAMED = 8,
        INDEX_TYPECHANGE = 16,
        WT_NEW = 128,
        WT_MODIFIED = 256,
        WT_DELETED = 512,
        WT_TYPECHANGE = 1024,
        WT_RENAMED = 2048,
        WT_UNREADABLE = 4096,
        IGNORED = 16384,
        CONFLICTED = 32768,
    }
}

---git status
---@param repo userdata
---@param opts userdata
---@return table<string, integer>
---@return table<string, integer>
function M.get_status(repo, opts)
    local list = git2.StatusList.new(repo, opts)
    if list == nil then
        return {}, {}
    end
    local committed_changes = {}
    local unstaged_changes = {}
    for i = 0, list:entrycount() - 1 do
        local entry = git2.StatusEntry.byindex(list, i)
        local delta = entry:index_to_workdir()
        local changes = unstaged_changes
        if delta == nil then
            delta = entry:head_to_index()
            changes = committed_changes
        end
        local file = delta:old_file()
        local path = file:path()
        local status = entry:status()
        changes[path] = status
    end
    return committed_changes, unstaged_changes
end

---format status
---@param status integer
---@return string[]
function M.format_status(status)
    local tags = {}
    for k, v in pairs(M.statuses) do
        if bit.band(v, status) == v then
            local tag = k:match("_(.*)") or k
            table.insert(tags, tag:lower())
        end
    end
    return tags
end

---format changes
---@param changes table<string, integer>
---@param lines string[]
function M.format_changes(changes, lines)
    for path, status in pairs(changes) do
        if status then
            table.insert(lines, ("    %s: %s"):format(table.concat(M.format_status(status), " "), path))
        end
    end
end

---format changes
---@param committed_changes table<string, integer>
---@param unstaged_changes table<string, integer>
---@return string[]
function M.format_all_changes(committed_changes, unstaged_changes)
    local lines = {}
    table.insert(lines, "Changes to be committed:")
    for path, status in pairs(committed_changes) do
        if status then
            table.insert(lines, ("    %s: %s"):format(table.concat(M.format_status(status), " "), path))
        end
    end
    table.insert(lines, "")
    table.insert(lines, "Changes not staged for commit:")
    for path, status in pairs(unstaged_changes) do
        if status then
            table.insert(lines, ("    %s: %s"):format(table.concat(M.format_status(status), " "), path))
        end
    end
    table.insert(lines, "")
    return lines
end

---git ls-files
---@param changes table<string, integer>
---@param tag integer
---@return string[]
function M.ls_files(changes, tag)
    local files = {}
    for path, status in pairs(changes) do
        if bit.band(tag, status) > 0 or tag == 0 then
            table.insert(files, path)
        end
    end
    return files
end

---for startify
---@param modified boolean
---@param others boolean
---@return string[]
function M.ls(modified, others)
    local fs = require "vim.fs"
    local fn = require "vim.fn"
    local git_dir = fs.root(fn.getcwd(), '.git')
    local repo = git2.Repository.open(git_dir)
    if repo == nil then
        return {}
    end
    local opts = git2.StatusOptions.init()
    opts:set_show(opts.SHOW_WORKDIR_ONLY)
    if others then
        opts:set_flags(opts:flags() + opts.INCLUDE_UNTRACKED)
    elseif not modified then
        opts:set_flags(opts:flags() + opts.INCLUDE_UNMODIFIED)
    end
    local _, unstaged_changes = M.get_status(repo, opts)
    local files = M.ls_files(unstaged_changes, others and M.statuses.WT_NEW or 0)
    return files
end

return M
