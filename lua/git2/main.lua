---core functions. only expand path for neovim not shell.
local git2 = require "git2"
local fs = require "vim.fs"
local fn = require "vim.fn"
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 113 212
local Parser = require "mega.argparse".Parser

local M = {}

---core function
---@param args table
function M.exe(args)
    local git_dir = fn.expand(args.C)
    git_dir = fs.root(git_dir, '.git')
    if args['rev-parse'] then
        if args.is_bare_repository then
            local repo, err = git2.Repository.open(git_dir)
            if repo == nil then
                print(('%s: %s'):format(git_dir, err))
                return
            end
            print(repo:is_bare())
        elseif args.show_toplevel then
            print(git_dir)
        else
            local dir = fs.joinpath(git_dir, '.git')
            if args.git_dir then
                print(fs.relpath(fn.getcwd(), dir))
            elseif args.absolute_git_dir then
                print(dir)
            end
        end
        return
    end
    if args.init then
        git2.Repository.init(args.directory, 0)
        return
    end
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
        local committed_changes, unstaged_changes = S.get_status(repo, opts, args.porcelain)
        local lines
        if args.status then
            if args.porcelain then
                lines = S.format_change(committed_changes)
            else
                lines = S.format_all_changes(committed_changes, unstaged_changes)
            end
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
        local arr = require 'git2.reset'.get_str_array(git_dir, args.file)
        idx:add_all(arr, 0)
    elseif args.rm or args.reset then
        for _, file in ipairs(args.file) do
            file = fn.expand(file)
            idx:remove(file, 0)
            if args.reset then
                file = fs.relpath(git_dir, file)
                local entry = require 'git2.reset'.get_index_entry(repo, file)
                idx:add(entry)
            elseif not args.cached then
                os.remove(file)
            end
        end
    end
    idx:write()
end

---get parser
---@return table
function M.get_parser()
    local parser = Parser {
        data = require "git2.data",
        callback = M.exe
    }
    return parser
end

---**entry for git2**
---@param argv string[]
function M.main(argv)
    local parser = M.get_parser()
    parser:parse(argv)
end

return M
