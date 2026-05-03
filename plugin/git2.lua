-- luacheck: ignore 111 113
---@diagnostic disable: undefined-global
local parser = require "git2.main".get_parser()
parser:create_user_command()
