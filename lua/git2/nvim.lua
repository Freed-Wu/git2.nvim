--- https://github.com/rhysd/committia.vim
-- luacheck: ignore 111 113
---@diagnostic disable: undefined-global
local M = {}

---create autocmds.
---@param augroup_id integer?
function M.create_autocmds(augroup_id)
    augroup_id = augroup_id or vim.api.nvim_create_augroup("git2", {})

    vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = { "COMMIT_EDITMSG", "MERGE_MSG" },
        group = augroup_id,
        callback = M.open_cb
    })

    vim.api.nvim_create_autocmd("QuitPre", {
        pattern = { "COMMIT_EDITMSG", "MERGE_MSG" },
        group = augroup_id,
        callback = M.quit_cb
    })
end

---callback for only once.
function M.open_cb()
    local committia = require 'git2.nvim.committia'
    if vim.b.committia == nil then
        committia.open()
    end
end

---callback for quit
function M.quit_cb()
    local committia = require 'git2.nvim.committia'
    committia.quit()
end

return M
