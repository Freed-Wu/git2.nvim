--- committia
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 112 113
local fs = require 'vim.fs'
local fn = require 'vim.fn'
local split = require 'vim.shared'.split
local git2 = require 'git2'
local D = require "git2.diff"
local M = {
    info = {
        gitcommit = {},
        diff = {},
    },
}

---open
function M.open()
    local repo_dir = '.'
    repo_dir = fs.root(repo_dir, '.git') or ''
    local repo, err = git2.Repository.open(repo_dir)
    if repo == nil then
        print(('%s: %s'):format(repo_dir, err))
        return
    end
    M.info.gitcommit.winnr = vim.api.nvim_get_current_win()
    M.info.gitcommit.bufnr = vim.api.nvim_get_current_buf()
    vim.b.committia = true
    vim.opt_local.splitright = true
    vim.opt_local.splitbelow = true
    local diff_content = D.diff(repo, { cached = true })
    if #diff_content > 0 then
        M.open_window(diff_content)
    end
end

---quit
function M.quit()
    local bufnr = vim.api.nvim_get_current_buf()
    if bufnr ~= M.info.gitcommit.bufnr then
        return
    end
    local winnr = M.info.diff.winnr
    if winnr == nil then
        return
    end
    vim.cmd(([[
    %dwincmd w
    wincmd c
]]):format(winnr))
end

---@param content string
---@param type string?
function M.open_window(content, type)
    type = type or 'diff'
    local cmd = M.info[type].cmd or 'vsplit'
    local bufname = M.info[type].bufname or ('__committia_' .. type .. '__')
    vim.cmd(([[silent %s %s]]):format(cmd, bufname))
    M.info[type].winnr = vim.fn.bufwinnr(bufname)
    M.info[type].bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(M.info[type].bufnr, 0, -1, false, split(fn.trim(content), '\n\r?'))
    vim.cmd [[0]]
    vim.opt_local.filetype = type
    vim.opt_local.number = false
    vim.opt_local.bufhidden = 'wipe'
    vim.opt_local.buftype = 'nofile'
    vim.opt_local.readonly = true
    vim.opt_local.list = false
    vim.opt_local.buflisted = false
    vim.opt_local.swapfile = false
    vim.opt_local.modifiable = false
    vim.opt_local.modified = false
    vim.opt_local.foldenable = false
end

---@param cmd string
---@return string
function M.get_map_of(cmd)
    if not cmd:match('%-') then
        return cmd
    end
    return vim.fn.eval(('"\\%s"'):format(cmd))
end

---@param cmd string
---@param type string
function M.scroll_window(cmd, type)
    type = type or 'diff'
    local winnr = (M.info[type] or {}).winnr or 0
    local map = M.get_map_of(cmd)
    vim.cmd(([[
    noautocmd %dwincmd w
    noautocmd normal! %s
    noautocmd wincmd p
]]):format(winnr, map))
end

return M
