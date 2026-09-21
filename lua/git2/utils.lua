---utilities
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 113 212
local M = {}

---@param err string?
function M.warn(err)
    if vim then
        vim.notify(err, vim.log.levels.WARN, { title = "git2.nvim" })
    else
        print(err)
    end
end

return M
