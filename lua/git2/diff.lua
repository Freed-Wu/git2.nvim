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
    ---@diagnostic disable: undefined-global
    -- luacheck: ignore 111 113
    if vim == nil then
        return fn.readfile(file)
    end
    local bufnr = fn.bufnr(file, true)
    if bufnr == -1 then
        return fn.readfile(file)
    end
    local lines = fn.getbufline(bufnr, 1, '$')
    if #lines == 0 then
        return fn.readfile(file)
    end
    return table.concat(lines, '\n') .. '\n'
end

---for `airline#extensions#hunks#get_raw_hunks()`
---@param root string?
---@param file string?
---@param new_text string?
---@param old_text string | integer?
---@return integer[] hunks added modified deleted
function M.get_raw_hunks(root, file, new_text, old_text)
    file = file or fn.expand('%:p')
    if file == '' then
        return {}
    end
    root = root or fs.dirname(file)
    local repo_dir = fs.root(root, '.git') or ''
    file = fs.relpath(repo_dir, file)
    local repo = git2.Repository.open(repo_dir)
    if repo == nil then
        return {}
    end

    local opts = git2.DiffOptions.init()

    if new_text == nil then
        new_text = M.read_buffer(file)
    end

    if type(old_text) ~= type('') then
        local blob
        if type(old_text) == type(0) then
            local idx = repo:index()
            local entry = idx:get_bypath(file, old_text)
            if entry then
                blob = git2.Blob.lookup(repo, entry:id())
            end
        elseif old_text == nil then
            blob = git2.Object.revparse_single(repo, 'HEAD:' .. file)
        end
        if blob == nil then
            return {}
        end
        old_text = blob:rawcontent()
    end

    local patch = git2.Patch.from_buffers(old_text, #old_text, file, new_text, #new_text, file, opts)
    if patch then
        return { M.count_patch(patch) }
    end
    return {}
end

---Build a `StrArray` pathspec from a string or list of strings.
---@param pathspec string | string[]?
---@return userdata? StrArray (nil when no pathspec)
local function to_str_array(pathspec)
    if type(pathspec) == 'string' then
        pathspec = { pathspec }
    end
    if type(pathspec) ~= 'table' or #pathspec == 0 then
        return nil
    end
    local arr = git2.StrArray(#pathspec)
    for i, p in ipairs(pathspec) do
        arr:set_str(i - 1, p)
    end
    return arr
end

---git diff -u
---Mirrors `git diff -u`:
---  * no `o.commit`, no `o.cached` -> unstaged changes (`index_to_workdir`)
---  * `o.cached` -> staged changes vs HEAD (`tree_to_index`)
---  * `o.commit` given -> changes vs that commit (`tree_to_workdir_with_index`)
---@param repo userdata
---@param o { cached?: boolean, commit?: string, pathspec?: string | string[] }?
---@return string unified diff text (empty string when nothing to show)
function M.diff(repo, o)
    o = o or {}
    local opts = git2.DiffOptions.init()
    opts:set_id_abbrev(7)
    local arr = to_str_array(o.pathspec)
    if arr then
        opts:set_pathspec(arr)
    end

    local diff
    if o.cached then
        local commit = git2.Object.revparse_single(repo, o.commit or 'HEAD')
        if commit == nil then
            return ''
        end
        local tree = commit:tree()
        if tree == nil then
            return ''
        end
        diff = git2.Diff.tree_to_index(repo, tree, repo:index(), opts)
    elseif o.commit then
        local commit = git2.Object.revparse_single(repo, o.commit)
        if commit == nil then
            return ''
        end
        local tree = commit:tree()
        if tree == nil then
            return ''
        end
        diff = git2.Diff.tree_to_workdir_with_index(repo, tree, opts)
    else
        diff = git2.Diff.index_to_workdir(repo, repo:index(), opts)
    end

    return diff and diff:to_buf(diff.FORMAT_PATCH) or ''
end

return M
