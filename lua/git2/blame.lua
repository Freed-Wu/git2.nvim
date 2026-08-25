---git blame
local fs = require "vim.fs"
local fn = require "vim.fn"
local git2 = require "git2"
local M = {}

---Parse a `-L` style line range into 1-based min/max line numbers.
---Supports "a,b" (both absolute, git semantics), "a,+n" (n lines from a),
---"a,-n" (n lines back from a), and "a" (single line).
---@param spec string
---@param total integer total number of lines in the file
---@return integer min_line 1-based inclusive (1 if unset)
---@return integer max_line 1-based inclusive (total if unset)
local function parse_line_range(spec, total)
    local a, off = spec:match("^(%d+),([+-]?%d+)$")
    if a then
        a, off = tonumber(a), tonumber(off)
        local b
        if off < 0 then
            -- "a,-n": n lines ending at a  -> [a-n+1, a] (git semantics)
            b = a + off + 1
        elseif spec:match("^(%d+),%+(%d+)$") then
            -- "a,+n": n lines starting at a -> [a, a+n-1]
            b = a + off - 1
        else
            -- "a,b": b is the absolute ending line
            b = off
        end
        local lo = math.min(a, b)
        local hi = math.max(a, b)
        return math.max(lo, 1), math.min(hi, total)
    end
    a = spec:match("^(%d+)$")
    if a then
        a = tonumber(a)
        return a, math.min(a, total)
    end
    return 1, total
end

---Format a git_time_t (seconds since epoch, UTC) as "YYYY-MM-DD".
---@param t integer seconds since epoch
---@return string
local function format_date(t)
    -- os.date with UTC to avoid depending on local timezone.
    return os.date("!%Y-%m-%d", t)
end

---git blame <file>
---Mirrors `git blame -p`-ish compact output:
---  <abbrev7> (<author> <YYYY-MM-DD> <line_no>) <line content>
---@param repo userdata
---@param o { file: string, line_range?: string, first_parent?: boolean,
---mailmap?: boolean, ignore_whitespace?: boolean }?
---@return string blame text (empty string when nothing to show / file not found)
function M.blame(repo, o)
    o = o or {}
    local file = o.file or fn.expand('%:p')
    if file == '' then
        return ''
    end
    local root = repo:workdir() or repo:path() or ''
    local rel = fs.relpath(root, file)
    if rel == nil then
        rel = file
    end
    -- Absolute path of the file inside the repo, used for reading content.
    local disk = fs.joinpath(root, rel)

    local opts = git2.BlameOptions.init()
    local flags = 0
    if o.first_parent then
        flags = flags + opts.FIRST_PARENT
    end
    if o.mailmap then
        flags = flags + opts.USE_MAILMAP
    end
    if o.ignore_whitespace then
        flags = flags + opts.IGNORE_WHITESPACE
    end
    if flags ~= 0 then
        opts:set_flags(flags)
    end

    local total = 0
    if o.line_range and o.line_range ~= '' then
        -- count lines to bound the range. Falls back to disk if no buffer
        -- is loaded (e.g. running from the plain-lua CLI).
        local fh = io.open(disk, 'r')
        if fh then
            for _ in fh:lines() do
                total = total + 1
            end
            fh:close()
        end
        local min_l, max_l = parse_line_range(o.line_range, math.max(total, 1))
        opts:set_min_line(min_l)
        opts:set_max_line(max_l)
    end

    local blame = git2.Blame.file(repo, rel, opts)
    if blame == nil then
        return ''
    end

    -- Read the file's lines so each blame line can be prefixed with its
    -- content (like `git blame`).
    local file_lines = {}
    local fh = io.open(disk, 'r')
    if fh then
        for line in fh:lines() do
            file_lines[#file_lines + 1] = line
        end
        fh:close()
    end

    local lines = {}
    local hc = blame:count()
    for i = 0, hc - 1 do
        local hunk = blame:get_hunk_byindex(i)
        if hunk == nil then
            break
        end
        local start_l = hunk:final_start_line_number()
        local lines_in_hunk = hunk:lines_in_hunk()
        local id = hunk:final_commit_id()
        local sig = hunk:final_signature()
        local abbrev = id and tostring(id):sub(1, 7) or "0000000"
        local author = sig and sig:name() or "unknown"
        local when = sig and (select(1, sig:when())) or 0
        local date = format_date(when)
        for l = start_l, start_l + lines_in_hunk - 1 do
            local content = file_lines[l] or ""
            table.insert(lines, ('%s (%s %s %d) %s'):format(abbrev, author, date, l, content))
        end
    end
    return table.concat(lines, "\n")
end

return M
