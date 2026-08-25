---Tests for git2.diff (get_raw_hunks / count_patch).
---
---Run with:  lua spec/diff_spec.lua
---Requires a compiled `git2` C module on the Lua CPath (e.g. produced from
---lua-git2-temp). If `git2` cannot be loaded, the suite is skipped.
---
---These tests build throwaway git repositories under a temp dir, so they only
---exercise the *real* libgit2-backed path. The pure pairing math is covered by
---the inline asserts on M.pair_hunks below, which run with no external deps.

package.path = ('.' .. '/lua/?.lua;' .. package.path)
local M = require 'git2.diff'
local function check(path, content, itw, x, y, z)
    local a, b, c = M.get_raw_hunks(nil, path, content, itw)
    assert.are.equal(a, x)
    assert.are.equal(b, y)
    assert.are.equal(c, z)
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
    os.execute('git -C ' .. dir .. ' add f; git -C ' .. dir .. ' commit -qm i 2>/dev/null')
end

describe('get_raw_hunks (index_to_workdir style)', function()
    it('modify one line -> [0,1,0]', function()
        repo_commit(TMP .. '/s-A', 'a\nb\nc\n')
        local f = io.open(TMP .. '/s-A/f', 'w'); f:write('a\nB\nc\n'); f:close()
        check(TMP .. '/s-A/f', nil, true, 0, 1, 0)
    end)
    it('move one line -> [1,0,1] (no false modification)', function()
        repo_commit(TMP .. '/s-Move', 'L1\nL2\nL3\nL4\nL5\nL6\nL7\nL8\nL9\nL10\n')
        local f = io.open(TMP .. '/s-Move/f', 'w')
        f:write('L1\nL3\nL4\nL5\nL6\nL7\nL8\nL9\nL10\nL2\n'); f:close()
        check(TMP .. '/s-Move/f', nil, true, 1, 0, 1)
    end)
    it('delete one line -> [0,0,1]', function()
        repo_commit(TMP .. '/s-Del', 'a\nb\nc\n')
        local f = io.open(TMP .. '/s-Del/f', 'w'); f:write('a\nc\n'); f:close()
        check(TMP .. '/s-Del/f', nil, true, 0, 0, 1)
    end)
end)

describe('get_raw_hunks (coc style, content arg)', function()
    it('unsaved modification -> [0,1,0]', function()
        repo_commit(TMP .. '/c-A', 'a\nb\nc\n')
        check(TMP .. '/c-A/f', 'a\nB\nc\n', nil, 0, 1, 0)
    end)
    it('unsaved move -> [1,0,1]', function()
        repo_commit(TMP .. '/c-Move', 'L1\nL2\nL3\nL4\nL5\nL6\nL7\nL8\nL9\nL10\n')
        check(TMP .. '/c-Move/f',
            'L1\nL3\nL4\nL5\nL6\nL7\nL8\nL9\nL10\nL2\n', nil, 1, 0, 1)
    end)
    it('unsaved deletion -> [0,0,1]', function()
        repo_commit(TMP .. '/c-Del', 'a\nb\nc\n')
        check(TMP .. '/c-Del/f', 'a\nc\n', nil, 0, 0, 1)
    end)
    it('new untracked file -> [3,0,0]', function()
        repo_commit(TMP .. '/c-New', '')
        check(TMP .. '/c-New/f', 'x\ny\nz\n', nil, 3, 0, 0)
    end)
end)
