---core functions
local git2 = require "git2"
local fs = require "git2.fs"
local get_parser = require "git2.argparse".get_parser
local data = require 'git2.data'.get()

local M = {}

---walk all directories except `.git/`
---@param idx table
---@param path string
---@param git_dir string
---@param callback function
function M.walk(idx, path, git_dir, callback)
    if fs.isdirectory(path) then
        for file in fs.dir(path) do
            if file ~= "." and file ~= ".." and file ~= ".git" then
                M.walk(idx, fs.joinpath(path, file), git_dir, callback)
            end
        end
    else
        local git_path = fs.relpath(git_dir, path)
        callback(idx, git_path)
    end
end

---process files from index to handle directory
---@param idx table
---@param file string
---@param callback function
function M.process_files_from_index(idx, file, callback)
    if idx:get_bypath(file, 0) then
        callback(idx, file)
    end
    for i = 0, idx:entrycount() - 1 do
        local path = idx:get_byindex(i):path()
        if path:sub(1, #file + 1) == file .. '/' then
            callback(idx, path)
        end
    end
end

---add file to index
---@param idx table
---@param file string
function M.add_file_to_index(idx, file)
    if fs.filereadable(file) then
        idx:add_bypath(file)
    else
        idx:remove(file, 0)
    end
end

---core function
---@param args table
function M.exe(args)
    if args['rev-parse'] then
        local git_dir = fs.getcwd()
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
    local git_dir = fs.expand(args.C)
    local repo = git2.Repository.open(git_dir)
    local idx = repo:index()

    if args.add then
        -- FIXME: https://github.com/libgit2/luagit2/issues/10
        -- current realization is slower than `git_index_add_all()`
        if args.A then
            args.file = { git_dir }
        end
        for _, file in ipairs(args.file) do
            if file:sub(1, 1) ~= "/" then
                file = fs.joinpath(fs.getcwd(), file)
            end
            local git_path = fs.relpath(git_dir, file)
            M.process_files_from_index(idx, git_path, M.add_file_to_index)
            M.walk(idx, fs.expand(file), git_dir, idx.add_bypath)
        end
    elseif args.rm then
        for _, file in ipairs(args.file) do
            file = fs.expand(file)
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
