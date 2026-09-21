package.path = 'lua/?.lua;lua/?/init.lua;' .. package.path

---Tests for git2.blame (M.blame / libgit2 blame bindings).
---
---Run with:  busted spec/blame_spec.lua
---Requires the `git2` C module on the Lua CPath (rebuilt from lua-git2-temp).
---
---Cases build throwaway git repositories under a temp dir and exercise the
---real libgit2-backed blame path.

local M = require 'git2.blame'
local data = require 'git2.data'
local git2 = require 'git2'

local TMP = (os.getenv('TMPDIR') or '/tmp') .. '/git2_nvim_blame_spec'

local function git_commit(dir, message)
    os.execute('git -C ' .. dir
        .. ' -c core.hooksPath=/dev/null -c commit.gpgsign=false commit --allow-empty --no-verify -qm '
        .. message .. ' 2>/dev/null')
end

---Build a repo with two commits touching `f`, then return its absolute path.
local function repo_two_commits(dir, base, changed)
    os.execute('rm -rf ' .. dir)
    os.execute('mkdir -p ' .. dir)
    os.execute('git -C ' .. dir .. ' init -q 2>/dev/null')
    os.execute('git -C ' .. dir .. ' config user.email t@t')
    os.execute('git -C ' .. dir .. ' config user.name tester')
    local f = io.open(dir .. '/f', 'w')
    assert(f)
    f:write(base)
    f:close()
    os.execute('git -C ' .. dir .. ' add f')
    git_commit(dir, 'base')
    local f2 = io.open(dir .. '/f', 'w')
    assert(f2)
    f2:write(changed)
    f2:close()
    os.execute('git -C ' .. dir .. ' add f')
    git_commit(dir, 'change')
    return dir
end

---Build a repo with committed lines, then append uncommitted lines to `f`.
local function repo_with_uncommitted_append(dir)
    os.execute('rm -rf ' .. dir)
    os.execute('mkdir -p ' .. dir)
    os.execute('git -C ' .. dir .. ' init -q 2>/dev/null')
    os.execute('git -C ' .. dir .. ' config user.email t@t')
    os.execute('git -C ' .. dir .. ' config user.name tester')
    local f = io.open(dir .. '/f', 'w')
    assert(f)
    f:write('a\nb\nc\n')
    f:close()
    os.execute('git -C ' .. dir .. ' add f')
    git_commit(dir, 'base')
    local f2 = io.open(dir .. '/f', 'a')
    assert(f2)
    f2:write('d\ne\n')
    f2:close()
    return dir
end

describe('git2.blame bindings', function()
    it('open repo + blame a single-line file', function()
        local dir = repo_two_commits(TMP .. '/one', 'hello\n', 'hello\n')
        local repo = assert(git2.Repository.open(dir))
        local blame = assert(git2.Blame.file(repo, 'f', git2.BlameOptions.init()))
        -- git_blame_linecount reflects libgit2's line accounting; just assert
        -- the single line is covered.
        assert.is_true(blame:linecount() >= 1)
        local hunk = blame:get_hunk_byindex(0)
        assert.is_not_nil(hunk)
        assert.are.equal(1, hunk:final_start_line_number())
        local id = hunk:final_commit_id()
        assert.is_not_nil(id)
        assert.are.equal(40, #tostring(id))
        local sig = hunk:final_signature()
        assert.is_not_nil(sig)
        assert.are.equal('tester', sig:name())
        assert.are.equal('t@t', sig:email())
        local when = select(1, sig:when())
        assert.is_number(when)
    end)

    it('multi-line file: every line resolves to an author', function()
        local dir = repo_two_commits(TMP .. '/multi', 'a\nb\nc\n', 'a\nB\nc\n')
        local repo = assert(git2.Repository.open(dir))
        local opts = git2.BlameOptions.init()
        local blame = assert(git2.Blame.file(repo, 'f', opts))
        -- git_blame_linecount may count an extra boundary line; assert coverage.
        assert.is_true(blame:linecount() >= 3)
        -- every line must map to a hunk with a resolved signature.
        for l = 1, 3 do
            local h = blame:get_hunk_byline(l)
            assert.is_not_nil(h)
            assert.is_not_nil(h:final_signature())
        end
        -- get_hunk_byline must agree with get_hunk_byindex on the first hunk.
        local h1 = blame:get_hunk_byindex(0)
        assert.are.equal(h1:final_start_line_number(),
            blame:get_hunk_byline(h1:final_start_line_number()):final_start_line_number())
    end)
end)

describe('git2.blame M.blame (CLI path)', function()
    it('blames a multi-line file with line content', function()
        local dir = repo_two_commits(TMP .. '/cli', 'a\nb\nc\n', 'a\nB\nc\n')
        local repo = assert(git2.Repository.open(dir))
        local out = M.blame(repo, { file = dir .. '/f' })
        assert.is_string(out)
        -- three annotated lines, each of the form: <sha> (<author> <date> <n>) <content>
        local n = 0
        for _ in out:gmatch('\n') do n = n + 1 end
        n = n + 1 -- trailing newline absent, count lines
        assert.are.equal(3, n)
        assert.is_not_nil(out:match('%(tester %d%d%d%d%-%d%d%-%d%d %d%) a'))
        assert.is_not_nil(out:match('%(tester %d%d%d%d%-%d%d%-%d%d %d%) B'))
        assert.is_not_nil(out:match('%(tester %d%d%d%d%-%d%d%-%d%d %d%) c'))
    end)

    it('--line-range 2,2 restricts to a single line', function()
        local dir = repo_two_commits(TMP .. '/range', 'a\nb\nc\n', 'a\nB\nc\n')
        local repo = assert(git2.Repository.open(dir))
        local out = M.blame(repo, { file = dir .. '/f', line_range = '2,2' })
        local n = 0
        for _ in out:gmatch('\n') do n = n + 1 end
        n = n + 1
        assert.are.equal(1, n)
        assert.is_not_nil(out:match('%) B$'))
    end)

    it('--line-range 2,+2 selects two lines from line 2', function()
        local dir = repo_two_commits(TMP .. '/range2', 'a\nb\nc\nd\ne\n', 'a\nB\nc\nd\ne\n')
        local repo = assert(git2.Repository.open(dir))
        local out = M.blame(repo, { file = dir .. '/f', line_range = '2,+2' })
        local n = 0
        for _ in out:gmatch('\n') do n = n + 1 end
        n = n + 1
        assert.are.equal(2, n)
        assert.is_not_nil(out:match('%) B'))
        assert.is_not_nil(out:match('%) c'))
    end)

    it('covers uncommitted appended lines with a null commit identity', function()
        local dir = repo_with_uncommitted_append(TMP .. '/uncommitted_append')
        local repo = assert(git2.Repository.open(dir))
        local blame = assert(M.collect(repo, { file = dir .. '/f' }))

        assert.are.equal(5, #blame.file_lines)
        local last = blame.hunks[#blame.hunks]
        assert.are.equal(4, last.start_line)
        assert.are.equal(2, last.lines_in_hunk)
        assert.are.equal('0000000', last.abbrev)
        assert.are.equal('', last.author)
        assert.are.equal('', last.email)
        assert.are.equal(os.date('!%Y-%m-%d'), last.date)

        local out = assert(M.blame(repo, { file = dir .. '/f' }))
        assert.is_not_nil(out:match('0000000 %(not%.committed%.yet %d%d%d%d%-%d%d%-%d%d 4%) d'))
        assert.is_not_nil(out:match('0000000 %(not%.committed%.yet %d%d%d%d%-%d%d%-%d%d 5%) e'))
    end)

    it('falls back to commit metadata when a real blame hunk has no signature', function()
        local original_blame_file = git2.Blame.file
        local original_commit_lookup = git2.Commit.lookup
        local dir = TMP .. '/signature_fallback'
        os.execute('rm -rf ' .. dir)
        os.execute('mkdir -p ' .. dir)
        local f = assert(io.open(dir .. '/f', 'w'))
        f:write('content\n')
        f:close()

        local oid = 'e118a36900000000000000000000000000000000'
        git2.Blame.file = function()
            return {
                count = function() return 1 end,
                get_hunk_byindex = function()
                    return {
                        final_start_line_number = function() return 1 end,
                        lines_in_hunk = function() return 1 end,
                        final_commit_id = function()
                            return setmetatable({}, { __tostring = function() return oid end })
                        end,
                        final_signature = function() return nil end,
                    }
                end,
            }
        end
        git2.Commit.lookup = function()
            return {
                author = function()
                    return {
                        name = function() return 'wuzhenyu' end,
                        email = function() return 'wuzhenyu@ustc.edu' end,
                        when = function() return 1790000000, 480 end,
                    }
                end,
                committer = function() return nil end,
            }
        end

        local ok, blame = pcall(M.collect, {
            workdir = function() return dir end,
            path = function() return dir .. '/.git/' end,
        }, { file = dir .. '/f' })

        git2.Blame.file = original_blame_file
        git2.Commit.lookup = original_commit_lookup

        assert.is_true(ok)
        local hunk = assert(blame.hunks[1])
        assert.are.equal('e118a36', hunk.abbrev)
        assert.are.equal('wuzhenyu', hunk.author)
        assert.are.equal('wuzhenyu@ustc.edu', hunk.email)
        assert.are.equal('2026-09-21', hunk.date)
    end)

    it('missing file reports an explicit error', function()
        local dir = repo_two_commits(TMP .. '/nofile', 'a\n', 'a\n')
        local repo = assert(git2.Repository.open(dir))
        local out, err = M.blame(repo, {})
        assert.is_nil(out)
        assert.are.equal('No file to blame.', err)
    end)

    it('nonexistent file returns the libgit2 error', function()
        local dir = repo_two_commits(TMP .. '/missing', 'a\n', 'a\n')
        local repo = assert(git2.Repository.open(dir))
        local out, err = M.blame(repo, { file = dir .. '/does_not_exist.txt' })
        assert.is_nil(out)
        assert.is_string(err)
        assert.is_true(#err > 0)
    end)
end)

describe('git2.data blame command metadata', function()
    it('allows zero or one file argument', function()
        local blame
        for _, subdata in ipairs(data) do
            if subdata[0].name == 'blame' then
                blame = subdata
                break
            end
        end
        assert.is_not_nil(blame)

        local file_arg
        for _, datum in ipairs(blame) do
            if datum.name == 'file' then
                file_arg = datum
                break
            end
        end
        assert.is_not_nil(file_arg)
        assert.are.equal('?', file_arg.nargs)
        assert.are.equal('%', file_arg.default)
    end)
end)

describe('git2.nvim.blame inline toggle', function()
    local original_vim
    local original_collect
    local state

    before_each(function()
        original_vim = _G.vim
        original_collect = M.collect
        state = {
            extmarks = 0,
            cleared = 0,
            collect_calls = 0,
            vars = {},
            notifications = {},
        }

        _G.vim = {
            api = {
                nvim_create_namespace = function() return 1 end,
                nvim_buf_clear_namespace = function()
                    state.cleared = state.cleared + 1
                    state.extmarks = 0
                end,
                nvim_buf_del_var = function(_, key)
                    if state.vars[key] == nil then
                        error('missing var')
                    end
                    state.vars[key] = nil
                end,
                nvim_buf_get_var = function(_, key)
                    if state.vars[key] == nil then
                        error('missing var')
                    end
                    return state.vars[key]
                end,
                nvim_buf_line_count = function() return 10 end,
                nvim_buf_get_lines = function() return { 'a' } end,
                nvim_buf_set_extmark = function()
                    state.extmarks = state.extmarks + 1
                    return state.extmarks
                end,
                nvim_buf_set_var = function(_, key, value)
                    state.vars[key] = value
                end,
                nvim_get_current_buf = function() return 3 end,
                nvim_buf_get_name = function() return '/tmp/repo/f' end,
            },
            fn = {
                strdisplaywidth = function(text) return #text end,
                fnamemodify = function(path) return path end,
            },
            log = {
                levels = {
                    WARN = 2,
                },
            },
            notify = function(msg)
                state.notifications[#state.notifications + 1] = msg
            end,
        }

        M.collect = function()
            state.collect_calls = state.collect_calls + 1
            return {
                hunks = {
                    {
                        start_line = 1,
                        lines_in_hunk = 1,
                        author = 'tester',
                        date = '2026-09-21',
                    },
                },
            }
        end

        package.loaded['git2.nvim.blame'] = nil
    end)

    after_each(function()
        M.collect = original_collect
        _G.vim = original_vim
        package.loaded['git2.nvim.blame'] = nil
    end)

    it('toggles inline blame off on repeated show', function()
        local inline = require 'git2.nvim.blame'

        assert.is_true(inline.toggle({}, { bufnr = 3 }))
        assert.are.equal(1, state.collect_calls)
        assert.is_true(state.vars.git2_blame_is_loaded)
        assert.are.equal(1, state.extmarks)

        assert.is_false(inline.toggle({}, { bufnr = 3 }))
        assert.are.equal(1, state.collect_calls)
        assert.is_nil(state.vars.git2_blame_is_loaded)
        assert.are.equal(0, state.extmarks)
    end)
end)
