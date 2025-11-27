---wrap `argparse` and `mega.cmdparse`
---@module mega.argparse
local argparse = require "argparse"
local ok, cmdparse = pcall(require, "mega.cmdparse")
local M = {
    Parser = {}
}

---wrap `argparse.Parser.option()` and `argparse.Parser.argument()`
---@param parser table
---@param name string
---@return table p
function M.argument(parser, name, ...)
    local f
    if name:sub(1, 1) == '-' then
        f = parser.option
    else
        f = parser.argument
    end
    return f(parser, name, ...)
end

---furthermore, wrap `argparse.Parser` to a similar API to `cmdparse.add_parameter()`
---@param parser table
---@param datum datum
---@return table p
function M.add_parameter(parser, datum)
    local p = M.argument(parser, datum.name, datum.help, datum.default)
    if datum.action == 'store_true' then
        datum.nargs = 0
    end
    if datum.nargs then
        p:args(datum.nargs)
    end
    return p
end

---wrap `argparse.Parser` to a similar API to `cmdparse.ParameterParser.new()`
---@param datum datum
function M.new(datum)
    return argparse(datum.name, datum.help):add_complete()
end

---wrap `argparse.Parser` to a similar API to `cmdparse.add_parser()`
---@param parser table
---@param datum datum
function M.add_parser(parser, datum)
    return parser:command(datum.name, datum.help)
end

---get parser
---@param data data
---@return table
function M.get_parser(data)
    local parser = M.new(data[0][0])
    for _, datum in ipairs(data[0]) do
        M.add_parameter(parser, datum)
    end

    for _, subdata in ipairs(data) do
        local subparser = M.add_parser(parser, subdata[0])
        for _, datum in ipairs(subdata) do
            M.add_parameter(subparser, datum)
        end
    end

    return parser
end

---get vim command parser
---@param data data
---@param callback function
---@return table
function M.get_cmd_parser(data, callback)
    local parser = cmdparse.ParameterParser.new(data[0][0])
    for _, datum in ipairs(data[0]) do
        parser:add_parameter(datum)
    end
    local parsers = parser:add_subparsers({ destination = "command" })

    for _, subdata in ipairs(data) do
        local subparser = parsers:add_parser(subdata[0])
        for _, datum in ipairs(subdata) do
            subparser:add_parameter(datum)
        end
        subparser:set_execute(function(d)
            d.namespace[subdata[0].name] = true
            callback(d.namespace)
        end)
    end

    return parser
end

---parser
---@section parser

---@param parser table?
---@return table parser
function M.Parser:new(parser)
    parser = parser or {}
    parser.data = parser.data or parser.get_data()
    parser.parser = M.get_parser(parser.data)
    if ok then
        parser.cmd_parser = M.get_cmd_parser(parser.data, parser.callback)
    end
    setmetatable(parser, {
        __index = self
    })
    return parser
end

setmetatable(M.Parser, {
    __call = M.Parser.new
})

---parse command line arguments
---@param argv string[]
---@return any
function M.Parser:parse(argv)
    self.parser._name = argv[0]
    local args = self.parser:parse(argv)
    return self.callback(args)
end

---create user command
function M.Parser:create_user_command(...)
    cmdparse.create_user_command(self.cmd_parser, ...)
end

return M
