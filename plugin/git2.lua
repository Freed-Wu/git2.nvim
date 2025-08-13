-- luacheck: ignore 111 113
---@diagnostic disable: undefined-global
local cmdparse = require "mega.cmdparse"
local cmd = require "git2.cmd"
cmdparse.create_user_command(cmd.get_cmd_parser())
