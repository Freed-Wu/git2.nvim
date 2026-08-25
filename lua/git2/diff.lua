---git diff
local fs = require 'vim.fs'
local fn = require 'vim.fn'
local git2 = require 'git2'
local M = {}

---Count added/modified/deleted lines of a patch by pairing insertions and
---deletions *per hunk*. Modifications are the overlap of `+` and `-` lines
---inside a single hunk; deletions and insertions from different hunks are
---never paired (so moving a line yields `[1, 0, 1]`, not `[0, 1, 0]`).
---@param patch userdata a git2.Patch
---@return integer added
---@return integer modified
---@return integer deleted
function M.count_patch(patch)
    local ins, mod, del = 0, 0, 0
    for h = 0, patch:num_hunks() - 1 do
        local add, dele = 0, 0
        for l = 0, patch:num_lines(h) - 1 do
            local o = patch:line_origin(h, l)
            if o == '+' then
                add = add + 1
            elseif o == '-' then
                dele = dele + 1
            end
        end
        local c = math.min(add, dele)
        ins, mod, del = ins + add - c, mod + c, del + dele - c
    end
    return ins, mod, del
end

---Read the current text of `file` from the Neovim buffer it is loaded in.
---@param file string absolute path
---@return string? content (nil if the file has no buffer loaded)
function M.read_buffer(file)
    local bufnr = fn.bufnr(file, true)
    if bufnr == -1 then
        return nil
    end
    local lines = fn.getbufline(bufnr, 1, '$')
    if #lines == 0 then
        return ''
    end
    return table.concat(lines, '\n') .. '\n'
end

---for `airline#extensions#hunks#get_raw_hunks()`
---@param root string?
---@param file string?
---@param content string? when set (coc style), diff this text against the
---  git-recorded version of the file; when nil and not `index_to_workdir`,
---  the text is taken from the Neovim buffer.
---@param index_to_workdir boolean? when true, diff the index against the
---  working tree (classic style); otherwise use coc style (default).
---@return integer[] hunks added modified deleted
function M.get_raw_hunks(root, file, content, index_to_workdir)
    file = file or fn.expand('%:p')
    root = root or fs.dirname(file)
    local repo_dir = fs.root(root, '.git') or ''
    file = fs.relpath(repo_dir, file)
    local repo = git2.Repository.open(repo_dir)
    if repo == nil then
        return { 0, 0, 0 }
    end

    local opts = git2.DiffOptions.init()

    if index_to_workdir then
        local idx = repo:index()
        local diff = git2.Diff.index_to_workdir(repo, idx, opts)
        local ins, mod, del = 0, 0, 0
        for j = 0, diff:num() - 1 do
            local patch = git2.Patch.from_diff(diff, j)
            if patch then
                local i, m, d = M.count_patch(patch)
                ins, mod, del = ins + i, mod + m, del + d
            end
        end
        return { ins, mod, del }
    end

    -- coc style: diff the git-recorded version against `content`
    if content == nil then
        content = M.read_buffer(file)
    end
    if content == nil then
        return { 0, 0, 0 }
    end

    local old = ''
    local ok, oid = pcall(git2.Blob.from_workdir, repo, file)
    if ok and oid then
        local blob = git2.Blob.lookup(repo, oid)
        if blob then
            old = blob:rawcontent() or ''
        end
    end

    local patch = git2.Patch.from_buffers(old, #old, file, content, #content, file, opts)
    if patch then
        return { M.count_patch(patch) }
    end
    return { 0, 0, 0 }
end

return M
