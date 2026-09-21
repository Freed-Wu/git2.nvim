---git blame
local fs = require "vim.fs"
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

---@param file string
---@return string relpath
---@return string disk
local function resolve_paths(repo, file)
    local root = repo:workdir() or repo:path() or ''
    local rel = fs.relpath(root, file)
    if rel == nil then
        return file, file
    end
    return rel, fs.joinpath(root, rel)
end

---@param o { first_parent?: boolean, mailmap?: boolean, ignore_whitespace?: boolean,
---line_range?: string }
---@param total integer
---@return userdata
local function build_options(o, total)
    o = o or {}
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

    if o.line_range and o.line_range ~= '' then
        local min_l, max_l = parse_line_range(o.line_range, math.max(total, 1))
        opts:set_min_line(min_l)
        opts:set_max_line(max_l)
    end
    return opts
end

---@param contents string
---@return string[]
local function split_lines(contents)
    local lines = {}
    contents = contents or ''
    if contents == '' then
        return lines
    end
    for line in (contents .. "\n"):gmatch("(.-)\n") do
        if line ~= '' or #lines > 0 or contents:sub(1, 1) == "\n" then
            lines[#lines + 1] = line
        end
    end
    if contents:sub(-1) == "\n" then
        lines[#lines] = nil
    end
    return lines
end

---@param disk string
---@return string
local function read_file_contents(disk)
    local fh = io.open(disk, 'r')
    if not fh then
        return ''
    end
    local contents = fh:read('*a') or ''
    fh:close()
    return contents
end

---@param id userdata?
---@return boolean
local function is_null_oid(id)
    return id ~= nil and tostring(id):match("^0+$") ~= nil
end

---@param sig userdata?
---@return table?
local function signature_info(sig)
    if sig == nil then
        return nil
    end

    return {
        author = sig:name(),
        email = sig:email(),
        when = select(1, sig:when()),
    }
end

---@param repo userdata
---@param id userdata?
---@return table?
local function commit_signature_info(repo, id)
    if id == nil then
        return nil
    end

    local commit = git2.Commit and git2.Commit.lookup and git2.Commit.lookup(repo, id)
    if commit == nil then
        return nil
    end

    return signature_info(commit:author()) or signature_info(commit:committer())
end

---@param blame userdata
---@param contents string
---@return userdata
---@return string? err
local function apply_buffer_blame(blame, contents)
    if type(blame.buffer) ~= "function" then
        return blame
    end

    local buffer_blame, err = blame:buffer(contents)
    if buffer_blame == nil then
        return nil, err
    end
    return buffer_blame
end

---Collect blame hunks for a single file.
---@param repo userdata
---@param o { file: string, line_range?: string, first_parent?: boolean,
---mailmap?: boolean, ignore_whitespace?: boolean, contents?: string }?
---@return table? blame_data
---@return string? err
function M.collect(repo, o)
    o = o or {}
    local file = o.file
    if file == nil or file == '' then
        return nil, 'No file to blame.'
    end

    local rel, disk = resolve_paths(repo, file)
    local contents = o.contents or read_file_contents(disk)
    local lines = split_lines(contents)
    local opts = build_options(o, #lines)
    local blame, err = git2.Blame.file(repo, rel, opts)
    if blame == nil then
        return nil, err
    end

    blame, err = apply_buffer_blame(blame, contents)
    if blame == nil then
        return nil, err
    end

    local hunks = {}
    local hc = blame:count()
    for i = 0, hc - 1 do
        local hunk = blame:get_hunk_byindex(i)
        if hunk == nil then
            break
        end
        local start_l = hunk:final_start_line_number()
        local lines_in_hunk = hunk:lines_in_hunk()
        local id = hunk:final_commit_id()
        local uncommitted = is_null_oid(id)
        local info = signature_info(hunk:final_signature())
            or (not uncommitted and commit_signature_info(repo, id) or nil)
        local when = info and info.when or (uncommitted and os.time() or 0)
        hunks[#hunks + 1] = {
            start_line = start_l,
            lines_in_hunk = lines_in_hunk,
            oid = id and tostring(id) or nil,
            abbrev = uncommitted and "0000000" or (id and tostring(id):sub(1, 7) or "0000000"),
            author = info and info.author or (uncommitted and "" or "unknown"),
            email = info and info.email or (uncommitted and "" or "unknown"),
            uncommitted = uncommitted,
            when = when,
            date = format_date(when),
        }
    end

    return {
        disk = disk,
        rel = rel,
        lines = lines,
        hunks = hunks,
    }
end

---git blame <file>
---Mirrors `git blame -p`-ish compact output:
---  <abbrev7> (<author> <YYYY-MM-DD> <line_no>) <line content>
---@param data table
---@return string text
function M.blame(data)
    local lines = {}
    for _, hunk in ipairs(data.hunks) do
        for l = hunk.start_line, hunk.start_line + hunk.lines_in_hunk - 1 do
            local content = data.lines[l] or ""
            table.insert(lines, ('%s (%s %s %d) %s'):format(
                hunk.abbrev,
                hunk.author,
                hunk.date,
                l,
                content
            ))
        end
    end
    return table.concat(lines, "\n")
end

return M
