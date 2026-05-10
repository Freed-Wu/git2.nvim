---git status
local bit = require "bit"
local git2 = require "git2"
local fs = require "vim.fs"

local M = {
    patterns = {
        index = { '[MARC][ MD]', 'D[ RC]' },
        wt = { '[ MARC][MD]', '[ D][RC]', 'DD', 'AU', 'UD', 'UA', 'DU', 'AA', 'UU', '??' },
    },
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
M.tag = {
    double = {
        [M.statuses.IGNORED] = '!!',
        [M.statuses.WT_NEW] = '??',
        [M.statuses.CONFLICTED] = 'UU',
    },
    index = {
        [M.statuses.INDEX_NEW] = 'A',
        [M.statuses.INDEX_MODIFIED] = 'M',
        [M.statuses.INDEX_DELETED] = 'D',
        [M.statuses.INDEX_RENAMED] = 'R',
        [M.statuses.INDEX_TYPECHANGE] = 'T',
    },
    wt = {
        [M.statuses.WT_MODIFIED] = 'M',
        [M.statuses.WT_DELETED] = 'D',
        [M.statuses.WT_RENAMED] = 'R',
        [M.statuses.WT_TYPECHANGE] = 'T',
    },
}

---git status
---@param repo userdata
---@param opts userdata
---@param porcelain boolean?
---@return table<string, integer>
---@return table<string, integer>
function M.get_status(repo, opts, porcelain)
    local list = git2.StatusList.new(repo, opts)
    if list == nil then
        return {}, {}
    end
    local committed_changes = {}
    local unstaged_changes = {}
    for i = 0, list:entrycount() - 1 do
        local entry = git2.StatusEntry.byindex(list, i)
        local delta = entry:head_to_index()
        local changes = committed_changes
        if delta == nil then
            delta = entry:index_to_workdir()
            if not porcelain then
                changes = unstaged_changes
            end
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

---format status
---@param status integer
---@return string
function M.format_porcelain_status(status)
    local tag = M.tag.double[status] or '  '
    if tag == '??' or tag == '!!' then
        return tag
    end
    for _, v in pairs(M.statuses) do
        if bit.band(v, status) == v then
            if M.tag.index[v] then
                tag = M.tag.index[v] .. tag:sub(2)
            elseif M.tag.wt[v] then
                tag = tag:sub(1, 1) .. M.tag.wt[v]
            end
        end
    end
    return tag
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

---format changes
---@param changes table<string, integer>
---@return string[]
function M.format_change(changes)
    local lines = {}
    for path, status in pairs(changes) do
        if status then
            table.insert(lines, ("%s %s"):format(M.format_porcelain_status(status), path))
        end
    end
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
---@param modified boolean?
---@param others boolean?
---@return string[]
function M.ls(modified, others)
    local repo_dir = fs.root('.', '.git')
    local repo = git2.Repository.open(repo_dir)
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
    local files = M.ls_files(unstaged_changes, others and M.statuses.WT_NEW or M.statuses.WT_MODIFIED)
    return files
end

---for fern.vim
---@param include_directories boolean?
---@param include_ignored boolean?
---@param include_untracked boolean?
---@return table<string, string>
function M.get_status_map(include_directories, include_ignored, include_untracked)
    local repo_dir = fs.root('.', '.git')
    local repo = git2.Repository.open(repo_dir)
    if repo == nil then
        return {}
    end
    local opts = git2.StatusOptions.init()
    if include_ignored then
        opts:set_flags(opts:flags() + opts.INCLUDE_IGNORED)
    end
    if include_untracked then
        opts:set_flags(opts:flags() + opts.INCLUDE_UNTRACKED)
    end
    local changes = M.get_status(repo, opts, true)
    local map = {}
    for path, status in pairs(changes) do
        if status then
            local tag = M.format_porcelain_status(status)
            map[path] = tag
        end
    end
    if include_directories then
        local dirs_map = M.complete_directories(map)
        for path, tag in pairs(dirs_map) do
            map[path] = tag
        end
    end
    local status_map = {}
    for path, tag in pairs(map) do
        path = fs.abspath(path)
        status_map[path] = tag
    end
    return status_map
end

---complete directories
---@param map table<string, string>
---@return table<string, string>
function M.complete_directories(map)
    local imap = {}
    local smap = {}
    for path, tag in pairs(map) do
        M.fill_map(imap, M.patterns.index, path, tag)
        M.fill_map(smap, M.patterns.wt, path, tag)
    end
    local dirs_map = {}
    for path, _ in pairs(imap) do
        dirs_map[path] = dirs_map[path] or ("%s%s"):format(imap[path] or ' ', smap[path] or ' ')
    end
    for path, _ in pairs(smap) do
        dirs_map[path] = dirs_map[path] or ("%s%s"):format(imap[path] or ' ', smap[path] or ' ')
    end
    return dirs_map
end

---fill a map
---@param imap table<string, string>
---@param patterns string[]
---@param path string
---@param tag string
function M.fill_map(imap, patterns, path, tag)
    path = fs.dirname(path)
    local is_matched = false
    for _, pattern in ipairs(patterns) do
        is_matched = is_matched or tag:match(pattern)
    end
    if is_matched then
        while path ~= '.' and path ~= '/' do
            imap[path] = '-'
            path = fs.dirname(path)
        end
    end
end

return M
