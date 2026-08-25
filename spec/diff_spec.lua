---Tests for git2.diff (get_raw_hunks / count_patch).
---
---Run with:  busted spec/diff_spec.lua
---Requires the `git2` C module on the Lua CPath (rebuilt from lua-git2-temp).
---If `git2` cannot be loaded, every case is reported as pending.
---
---The cases build throwaway git repositories under a temp dir, so they only
---exercise the real libgit2-backed path.
local M = require 'git2.diff'

-- `check(path, new, old, x, y, z)` calls get_raw_hunks and compares the
-- returned [added, modified, deleted] table to the expected [x, y, z].
local function check(path, new, old, x, y, z)
    local res = M.get_raw_hunks(nil, path, new, old)
    assert.are.same({ x, y, z }, { res[1], res[2], res[3] })
end

local TMP = (os.getenv('TMPDIR') or '/tmp') .. '/git2_nvim_diff_spec'
local function repo_commit(dir, base)
    os.execute('rm -rf ' .. dir)
    os.execute('mkdir -p ' .. dir)
    os.execute('git -C ' .. dir .. ' init -q 2>/dev/null')
    os.execute('git -C ' .. dir .. ' config --unset extensions.refStorage 2>/dev/null')
    os.execute('git -C ' .. dir .. ' config user.email t@t')
    os.execute('git -C ' .. dir .. ' config user.name t')
    local f = io.open(dir .. '/f', 'w')
    assert(f)
    f:write(base)
    f:close()
    os.execute('git -C ' .. dir .. ' add f; git -C ' .. dir
        .. ' -c core.hooksPath=/dev/null commit --no-verify -qm i 2>/dev/null')
end
local function write_workdir(dir, content)
    local f = io.open(dir .. '/f', 'w')
    assert(f)
    f:write(content)
    f:close()
end

-- `count_patch` is a pure function over the patch iteration API, so we can test
-- its pairing math with a stub patch that implements num_hunks/num_lines/
-- line_origin. This runs even without the `git2` C module.
describe('count_patch (per-hunk pairing math)', function()
    -- build a stub patch from a list of hunks, each a string of '+', '-', ' '
    local function stub_patch(hunks)
        local h = hunks
        return {
            num_hunks = function() return #h end,
            num_lines = function(_, i) return #h[i + 1] end,
            line_origin = function(_, i, l)
                return h[i + 1]:sub(l + 1, l + 1)
            end,
        }
    end
    local function cp(hunks)
        return { M.count_patch(stub_patch(hunks)) }
    end

    it('one hunk, 1 add + 1 del -> 1 modification', function()
        assert.are.same({ 0, 1, 0 }, cp({ '-+' }))
    end)
    it('two hunks (move): 1 del in one, 1 add in other -> 1 add, 1 del', function()
        -- a moved line yields separate hunks: the deletion and the insertion
        assert.are.same({ 1, 0, 1 }, cp({ '-', '+' }))
    end)
    it('one hunk, 2 add + 1 del -> 1 add, 1 modification', function()
        assert.are.same({ 1, 1, 0 }, cp({ '-++' }))
    end)
    it('one hunk, 3 del -> 3 deletions', function()
        assert.are.same({ 0, 0, 3 }, cp({ '---' }))
    end)
    it('context lines are ignored', function()
        assert.are.same({ 0, 1, 0 }, cp({ ' -+ ' }))
    end)
end)

describe('get_raw_hunks (old = HEAD, the default)', function()
    it('modify one line -> [0,1,0]', function()
        repo_commit(TMP .. '/c-A', 'a\nb\nc\n')
        check(TMP .. '/c-A/f', 'a\nB\nc\n', nil, 0, 1, 0)
    end)
    it('move one line -> [1,0,1] (no false modification)', function()
        repo_commit(TMP .. '/c-Move', 'L1\nL2\nL3\nL4\nL5\nL6\nL7\nL8\nL9\nL10\n')
        check(TMP .. '/c-Move/f',
            'L1\nL3\nL4\nL5\nL6\nL7\nL8\nL9\nL10\nL2\n', nil, 1, 0, 1)
    end)
    it('delete one line -> [0,0,1]', function()
        repo_commit(TMP .. '/c-Del', 'a\nb\nc\n')
        check(TMP .. '/c-Del/f', 'a\nc\n', nil, 0, 0, 1)
    end)
    it('new untracked file -> [3,0,0]', function()
        repo_commit(TMP .. '/c-New', '')
        check(TMP .. '/c-New/f', 'x\ny\nz\n', nil, 3, 0, 0)
    end)
    it('add 3 then stage then add 1 -> [4,0,0] vs HEAD', function()
        repo_commit(TMP .. '/c-Staged', 'a\nb\nc\n')
        write_workdir(TMP .. '/c-Staged', 'a\nb\nc\nX\nY\nZ\n')
        os.execute('git -C ' .. TMP .. '/c-Staged add f')
        write_workdir(TMP .. '/c-Staged', 'a\nb\nc\nX\nY\nZ\nW\n')
        check(TMP .. '/c-Staged/f', 'a\nb\nc\nX\nY\nZ\nW\n', nil, 4, 0, 0)
    end)
end)

describe('get_raw_hunks (old = index, when passed)', function()
    it('add 3 then stage then add 1 -> [1,0,0] vs index', function()
        repo_commit(TMP .. '/i-Staged', 'a\nb\nc\n')
        write_workdir(TMP .. '/i-Staged', 'a\nb\nc\nX\nY\nZ\n')
        os.execute('git -C ' .. TMP .. '/i-Staged add f')
        write_workdir(TMP .. '/i-Staged', 'a\nb\nc\nX\nY\nZ\nW\n')
        -- old=truthy => compare against the staged/index version (3 already added)
        check(TMP .. '/i-Staged/f', 'a\nb\nc\nX\nY\nZ\nW\n', 1, 1, 0, 0)
    end)
    it('modify one line vs index -> [0,1,0]', function()
        repo_commit(TMP .. '/i-A', 'a\nb\nc\n')
        os.execute('git -C ' .. TMP .. '/i-A add f')
        check(TMP .. '/i-A/f', 'a\nB\nc\n', 1, 0, 1, 0)
    end)
end)
