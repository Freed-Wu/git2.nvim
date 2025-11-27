-- luacheck: ignore 111 113
---@diagnostic disable: undefined-global
local cmdparse = require "mega.cmdparse"
local data = require "git2.data".get()
local exe = require "git2.main".exe
local parser = require "mega.argparse".get_cmd_parser(data, exe)
cmdparse.create_user_command(parser)
