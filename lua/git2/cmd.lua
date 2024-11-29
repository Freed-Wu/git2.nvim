local git2 = require "git2"
local argparse = require "argparse"
local utils = require "git2.utils"

local M = {}

---get parser
---@return table
local function get_parser()
    local parser = argparse("git", "a git implemented by lua")
    parser:option("-C", "run as if git was started in given path", utils.get_toplevel(utils.getcwd()))

    parser:command("init", "Create an empty Git repository or reinitialize an existing one")
        :argument("directory", "Where to init the repository (optional)", utils.getcwd())

    local cmd = parser:command("add", "Add file contents to the index")
    cmd:option("-A", "add, modify, and remove index entries to match the working tree")
    cmd:argument("file", "file to be added", "")

    return parser
end

---main function
---@param input string[]
---@return nil
function M.git(input)
    local args = get_parser():parse(input)
    if args.init then
        git2.Repository.init(args.directory, 0)
    elseif args.add then
        local repo = git2.Repository.open(utils.expand(args.C))
        local idx = repo:index()
        if args.A then
            -- https://github.com/libgit2/luagit2/issues/10
            return
        end
        idx:add_bypath(utils.expand(args.file))
        idx:write()
    end
end

return M
