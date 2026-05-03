---store data for parsers.

---@alias datum
---| {
---    name: string | string[],
---    help: string,
---    default: any,
---    nargs: integer | string?,
---    action: string?}
---@alias subdata table<integer, datum>
---@alias data table<integer, subdata>

---get parser data
---@return data data
return {
    -- parser
    [0] = {
        [0] = {
            name = "Git",
            help = "a git implemented by lua"
        },
        {
            name = "-C",
            default = ".",
            help = "run as if git was started in given path"
        }
    },
    -- subparser
    {
        [0] = {
            name = "init",
            help =
            "Create an empty Git repository or reinitialize an existing one"
        },
        {
            name = "directory",
            default = ".",
            help = "Where to init the repository (optional)"
        }
    },
    {
        [0] = {
            name = "add",
            help = "Add file contents to the index"
        },
        {
            name = "-A",
            action = "store_true",
            help =
            "add, modify, and remove index entries to match the working tree"
        },
        {
            name = "file",
            nargs = '*',
            help = "file to be added"
        }
    },
    {
        [0] = {
            name = "reset",
            help = "Reset current HEAD to the specified state"
        },
        {
            name = "file",
            nargs = '*',
            help = "file to be reset"
        }
    },
    {
        [0] = {
            name = "rm",
            help = "Remove files from the working tree and from the index"
        },
        {
            name = "--cached",
            action = "store_true",
            help =
            "only remove files from the index"
        },
        {
            name = "file",
            nargs = '*',
            help = "file to be removed"
        }
    },
    {
        [0] = {
            name = "rev-parse",
            help = "Pick out and massage parameters"
        },
        {
            name = "--git-dir",
            action = "store_true",
            help = "Show the path to the .git directory. \
The path shown, when relative, is relative to the current working directory."
        },
        {
            name = "--absolute-git-dir",
            action = "store_true",
            help = "Like --git-dir, but its output is always the canonicalized absolute path."
        },
        {
            name = "--is-bare-repository",
            action = "store_true",
            help = 'When the repository is bare print "true", otherwise "false".'
        },
        {
            name = "--show-top-level",
            action = "store_true",
            help = 'show absolute path of top-level directory'
        },
    },
    {
        [0] = {
            name = "status",
            help = "Show the working tree status"
        },
        {
            name = "--ignored",
            action = "store_true",
            help = 'show ignored files as well'
        },
        {
            name = "--untracked-files",
            default = "all",
            help = 'show untracked files'
        },
    },
    {
        [0] = {
            name = "ls-files",
            help = "information about files in index/working directory"
        },
        {
            name = { "-o", "--others" },
            action = "store_true",
            help = 'show other files in output'
        },
        {
            name = { "-m", "--modified" },
            action = "store_true",
            help = 'show modified files in output'
        },
        {
            name = "--exclude-standard",
            action = "store_true",
            help = 'skip files in standard Git exclusion lists'
        },
    },
}
