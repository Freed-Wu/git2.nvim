local git2 = require "git2"
local argparse = require "argparse"
local cmdparse = require "mega.cmdparse"
local lfs = require "lfs"
local utils = require "git2.utils"

local M = {}

---get `.git` directory
---@param dir string
---@return string
function M.get_gitdir(dir)
    while dir ~= "/" do
        if utils.isdirectory(utils.joinpath(dir, ".git")) then
            return dir
        end
        dir = utils.dirname(dir)
    end
    return ""
end

---get parser
---@return table
local function get_parser()
    local parser = argparse("git", "a git implemented by lua"):add_complete()
    parser:option("-C", "run as if git was started in given path", M.get_gitdir(utils.getcwd()))

    parser:command("init", "Create an empty Git repository or reinitialize an existing one")
        :argument("directory", "Where to init the repository (optional)", utils.getcwd())

    local cmd = parser:command("add", "Add file contents to the index")
    cmd:option("-A", "add, modify, and remove index entries to match the working tree"):args(0)
    cmd:argument("file", "file to be added"):args("*")

    return parser
end

---get vim command parser
---@return table
function M.get_cmd_parser()
    local parser = cmdparse.ParameterParser.new({ name = "Git", help = "a git implemented by lua" })
    parser:add_parameter({ name = "-C", help = "run as if git was started in given path" })
    local parsers = parser:add_subparsers({ destination = "command" })

    local subparser = parsers:add_parser({
        name = "init",
        help =
        "Create an empty Git repository or reinitialize an existing one"
    })
    subparser:add_parameter({
        name = "directory",
        required = false,
        help =
        "Where to init the repository (optional)"
    })
    subparser:set_execute(function(data)
        data.namespace.init = true
        data.namespace.C = data.namespace.C or M.get_gitdir(utils.getcwd())
        data.namespace.directory = data.namespace.directory or utils.getcwd()
        M.exe(data.namespace)
    end)

    subparser = parsers:add_parser({ name = "add", help = "Add file contents to the index" })
    subparser:add_parameter({
        name = "-A",
        nargs = 0,
        help =
        "add, modify, and remove index entries to match the working tree"
    })
    subparser:add_parameter({
        name = "file",
        nargs = '*',
        help = "file to be added"
    })
    subparser:set_execute(function(data)
        data.namespace.add = true
        data.namespace.C = data.namespace.C or M.get_gitdir(utils.getcwd())
        M.exe(data.namespace)
    end)

    return parser
end

---get path relative to git directory
---@param path string
---@param cwd string
---@param git_dir string
---@return string path
function M.get_git_path(path, cwd, git_dir)
    if path:sub(1, 1) ~= "/" then
        path = utils.joinpath(cwd, path)
    end
    path = path:gsub("/%./", "/")
    while path:match("/%.%./") do
        path = path:gsub("/[^/]+/%.%./", "/", 1)
    end
    local pat = git_dir:gsub("%-", "%-")
    path = path:gsub(pat .. "/", "")
    return path
end

---walk all directories except `.git/`
---@param dir string
---@param callback function
function M.walk(dir, callback)
    if utils.isdirectory(dir) then
        for file in lfs.dir(dir) do
            if file ~= "." and file ~= ".." and file ~= ".git" then
                M.walk(utils.joinpath(dir, file), callback)
            end
        end
    else
        callback(dir)
    end
end

function M.exe(args)
    if args.init then
        git2.Repository.init(args.directory, 0)
    elseif args.add then
        local repo = git2.Repository.open(utils.expand(args.C))
        local idx = repo:index()

        local function callback(file)
            idx:add_bypath(M.get_git_path(file, utils.getcwd(), args.C))
        end

        -- https://github.com/libgit2/luagit2/issues/10
        if args.A then
            M.walk(args.C, callback)
        else
            for _, file in ipairs(args.file) do
                M.walk(utils.expand(file), callback)
            end
        end
        idx:write()
    end
end

---**entry for git2**
---@param argv string[]
function M.main(argv)
    local args = get_parser():parse(argv)
    M.exe(args)
end

return M
