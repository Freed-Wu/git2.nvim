local git2 = require "git2"
local argparse = require "argparse"

local function getcwd()
    if vim then
        return vim.fn.getcwd()
    end
    return require "lfs".currentdir()
end

local function isdirectory(dir)
    if vim then
        return vim.fn.isdirectory(dir) == 1
    end
    return require "lfs".attributes(dir).mode == "directory"
end

local function joinpath(dir, file)
    if vim then
        return vim.fs.joinpath(dir, file)
    end
    return dir .. "/" .. file
end

local function get_toplevel(dir)
    while dir ~= "/" do
        if isdirectory(joinpath(dir, ".git")) then
            return dir
        end
        dir = vim.fs.dirname(dir)
    end
    return ""
end

local M = {}

local parser = argparse("git", "a git implemented by lua")
parser:option("-C", "run as if git was started in given path", get_toplevel(getcwd()))

parser:command("init", "Create an empty Git repository or reinitialize an existing one")
    :argument("directory", "Where to init the repository (optional)", getcwd())

local cmd = parser:command("add", "Add file contents to the index")
cmd:option("-A", "add, modify, and remove index entries to match the working tree")
cmd:argument("file", "file to be added", "")

function M.git(input)
    local args = parser:parse(input)
    if args.init then
        git2.Repository.init(args.directory, 0)
    elseif args.add then
        local repo = git2.Repository.open(vim.fn.expand(args.C))
        local idx = repo:index()
        if args.A then
            -- https://github.com/libgit2/luagit2/issues/10
            return
        end
        idx:add_bypath(vim.fn.expand(args.file))
        idx:write()
    end
end

return M
