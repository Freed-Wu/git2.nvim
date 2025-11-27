---core functions
local git2 = require "git2"
local fs = require "vim.fs"
local fn = require "vim.fn"
local get_parser = require "mega.argparse".get_parser
local data = require 'git2.data'.get()

local M = {}

---core function
---@param args table
function M.exe(args)
    if args['rev-parse'] then
        local git_dir = fn.getcwd()
        if args.git_dir then
            git_dir = '.'
        end
        git_dir = fs.root(git_dir, '.git')
        if args.is_bare_repository then
            local repo = git2.Repository.open(git_dir)
            print(repo:is_bare())
        else
            print(git_dir)
        end
        return
    end
    if args.init then
        git2.Repository.init(args.directory, 0)
        return
    end
    local git_dir = fn.expand(args.C)
    local repo = git2.Repository.open(git_dir)
    if repo == nil then
        print(args.C .. ' is not a git repository!')
        return
    end
    local idx = repo:index()

    if args.add then
        if args.A then
            args.file = { git_dir }
        end
        for _, file in ipairs(args.file) do
            if file:sub(1, 1) ~= "/" then
                file = fs.joinpath(fn.getcwd(), file)
            end
            idx:add_all(git2.StrArray(file), 0)
        end
    elseif args.rm then
        for _, file in ipairs(args.file) do
            file = fn.expand(file)
            idx:remove(file, 0)
            if not args.cached then
                os.remove(file)
            end
        end
    end
    idx:write()
end

---**entry for git2**
---@param argv string[]
function M.main(argv)
    data[0][0].name = argv[0]
    local args = get_parser(data):parse(argv)
    M.exe(args)
end

return M
