-- luacheck: ignore 111 113
---@diagnostic disable: undefined-global
vim.api.nvim_create_user_command("Git", function(args)
    require "git2.cmd".git(args.fargs)
end, { nargs = "*" })
