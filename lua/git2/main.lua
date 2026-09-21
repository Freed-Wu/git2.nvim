---core functions. only expand path for neovim not shell.
local git2 = require "git2"
local fs = require "vim.fs"
local fn = require "vim.fn"
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 113 212
local Parser = require "mega.argparse".Parser

local M = {}

---@param file string|string[]|nil
---@return string|nil
---@return boolean
---@return string|nil
local function normalize_blame_file(file)
    if type(file) == type {} then
        if #file == 0 then
            return nil, false
        end
        if #file > 1 then
            return nil, false, "git blame expects at most one file"
        end
        file = file[1]
    end
    if file == nil or file == '' then
        return nil, false
    end
    local default_current_buffer = file == '%'
    return fn.expand(file), default_current_buffer
end

---core function
---@param args table
function M.exe(args)
    local repo_dir = fn.expand(args.C)
    repo_dir = fs.root(repo_dir, '.git') or ''
    if args['rev-parse'] then
        if args.is_bare_repository then
            local repo, err = git2.Repository.open(repo_dir)
            if repo == nil then
                print(('%s: %s'):format(repo_dir, err))
                return
            end
            print(repo:is_bare())
        elseif args.show_toplevel then
            print(repo_dir)
        elseif args.git_dir or args.absolute_git_dir then
            local git_dir = fs.joinpath(repo_dir, '.git')
            if fn.isdirectory(git_dir) == 1 then
                if args.git_dir then
                    git_dir = fs.relpath(fn.getcwd(), git_dir)
                end
            else
                gitdir = require 'yaml'.loadpath(git_dir).gitdir
            end
            print(git_dir)
        end
        return
    end
    if args.init then
        git2.Repository.init(args.directory, 0)
        return
    end
    local repo, err = git2.Repository.open(repo_dir)
    if repo == nil then
        print(('%s: %s'):format(repo_dir, err))
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

    if args.diff then
        local D = require 'git2.diff'
        local text = D.diff(repo, {
            cached = args.cached,
            commit = args.commit,
            pathspec = args.pathspec,
        })
        if #text > 0 then
            print((text:gsub('\n$', '')))
        end
        return
    end

    if args.blame then
        local B = require 'git2.blame'
        local file, default_current_buffer, file_err = normalize_blame_file(args.file)
        if file_err ~= nil then
            print(file_err)
            return
        end
        if default_current_buffer and vim ~= nil and vim.api and vim.api.nvim_get_current_buf then
            require('git2.nvim.blame').show(repo, {
                line_range = args.line_range,
                first_parent = args.first_parent,
                mailmap = args.mailmap,
                ignore_whitespace = args.ignore_whitespace,
            })
            return
        end
        local text, blame_err = B.blame(repo, {
            file = file,
            line_range = args.line_range,
            first_parent = args.first_parent,
            mailmap = args.mailmap,
            ignore_whitespace = args.ignore_whitespace,
        })
        if blame_err ~= nil then
            print(blame_err)
            return
        end
        if text ~= nil and #text > 0 then
            print((text:gsub('\n$', '')))
        end
        return
    end

    if args.add then
        if args.A then
            args.file = { repo_dir }
        end
        local arr = require 'git2.reset'.get_str_array(repo_dir, args.file)
        idx:add_all(arr, 0)
    elseif args.rm or args.reset then
        for _, file in ipairs(args.file) do
            file = fn.expand(file)
            idx:remove(file, 0)
            if args.reset then
                file = fs.relpath(repo_dir, file)
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
