---core functions. only expand path for neovim not shell.
local git2 = require "git2"
local fs = require "vim.fs"
local fn = require "vim.fn"
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 113 212
local expand = vim and fn.expand or function(dir) return dir end
local Parser = require "mega.argparse".Parser

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
            local repo, err = git2.Repository.open(git_dir)
            if repo == nil then
                print(('%s: %s'):format(git_dir, err))
                return
            end
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
    local git_dir = expand(args.C)
    local repo, err = git2.Repository.open(git_dir)
    if repo == nil then
        print(('%s: %s'):format(git_dir, err))
        return
    end
    if args.status or args["ls-files"] then
        local S = require 'git2.status'
        local opts = git2.StatusOptions.init()
        if args["ls-files"] then
            opts:set_show(opts.SHOW_WORKDIR_ONLY)
            args.ignored = not args.exclude_standard and not args.modified
            args.untracked_files = args.others and "all" or "no"
            if not args.modified and not args.others then
                opts:set_flags(opts:flags() + opts.INCLUDE_UNMODIFIED)
            end
        end
        if args.untracked_files == "all" then
            opts:set_flags(opts:flags() + opts.INCLUDE_UNTRACKED)
        end
        if args.ignored then
            opts:set_flags(opts:flags() + opts.INCLUDE_IGNORED)
        end
        local committed_changes, unstaged_changes = S.get_status(repo, opts)
        local lines
        if args.status then
            lines = S.format_all_changes(committed_changes, unstaged_changes)
        else
            lines = S.ls_files(unstaged_changes, args.others and S.statuses.WT_NEW + S.statuses.IGNORED or 0)
        end
        print(table.concat(lines, "\n"))
        return
    end
    local idx = repo:index()

    if args.add then
        if args.A then
            args.file = { git_dir }
        end
        local arr = git2.StrArray(#args.file)
        for i, file in ipairs(args.file) do
            file = fs.relpath(git_dir, file)
            -- c index from 0
            if file then
                arr:set_str(i - 1, file)
            end
        end
        idx:add_all(arr, 0)
    elseif args.rm or args.reset then
        for _, file in ipairs(args.file) do
            file = expand(file)
            idx:remove(file, 0)
            if args.reset then
                require 'git2.reset'.reset(repo, idx, file)
            elseif not args.cached then
                os.remove(file)
            end
        end
    end
    idx:write()
end

---**entry for git2**
---@param argv string[]
function M.main(argv)
    local parser = Parser {
        get_data = require "git2.data".get,
        callback = M.exe
    }
    parser:parse(argv)
end

return M
