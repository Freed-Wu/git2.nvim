-- luacheck: ignore 111 113
---@diagnostic disable: undefined-global
local Parser = require "mega.argparse".Parser

local parser = Parser {
    get_data = require "git2.data".get,
    callback = require "git2.main".exe
}
parser:create_user_command()
