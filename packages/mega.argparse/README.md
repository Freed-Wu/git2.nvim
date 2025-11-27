# mega.argparse

Wrap argparse and mega.cmdparse.

`plugin/git.lua`:

```lua
#!/usr/bin/env lua
local data = {
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
                name = "add",
                help =
                "add, modify, and remove index entries to match the working tree"
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
        -- ...
    }
}
local function exe(args)
    local argv = {"git"}
    if args.add then
        table.insert(argv, "add")
        if args.A then
            table.insert(argv, "-A")
        end
        for _, file in ipairs(args.file) do
            table.insert(argv, file)
        end
    end
    local cmd = table.concat(argv)
    local p = io.popen(cmd)
    local stdout = ""
    if p then
        stdout = p:read("*a")
        p:close()
    end
    print(stdout)
end

local Parser = require "mega.argparse".Parser
local parser = Parser {
    data = data,
    --- or
    -- get_data = function () return data end,
    callback = exe
}
if vim then
    parser:create_user_command()
else
    parser:parse(args)
end
```

Now it is:

- a vim plugin with a command `:Git add -A file`
- an executable file which can be run by `lua plugin/git.lua add -A file`
