---Tests for git2.blame (M.blame / libgit2 blame bindings).
---
---Run with:  busted spec/blame_spec.lua
---Requires the `git2` C module on the Lua CPath (rebuilt from lua-git2-temp).
---
---Cases build throwaway git repositories under a temp dir and exercise the
---real libgit2-backed blame path.

local M = require 'git2.blame'
local git2 = require 'git2'

local TMP = (os.getenv('TMPDIR') or '/tmp') .. '/git2_nvim_blame_spec'

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
    os.execute('git -C ' .. dir .. ' add f; git -C ' .. dir
        .. ' -c core.hooksPath=/dev/null commit --no-verify -qm base 2>/dev/null')
    local f2 = io.open(dir .. '/f', 'w')
    assert(f2)
    f2:write(changed)
    f2:close()
    os.execute('git -C ' .. dir .. ' add f; git -C ' .. dir
        .. ' -c core.hooksPath=/dev/null commit --no-verify -qm change 2>/dev/null')
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

    it('nonexistent file yields empty string', function()
        local dir = repo_two_commits(TMP .. '/missing', 'a\n', 'a\n')
        local repo = assert(git2.Repository.open(dir))
        local out = M.blame(repo, { file = dir .. '/does_not_exist.txt' })
        assert.are.equal('', out)
    end)
end)
