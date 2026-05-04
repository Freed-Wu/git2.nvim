package.path = package.path .. ';lua/?.lua'

local S = require "git2.status"

-- luacheck: ignore 113
---@diagnostic disable: undefined-global
describe("test", function()
    it("tests parse key", function()
        local map = { ["a/b/c"] = " M" }
        local dirs_map = S.complete_directories(map)
        local expected = { ["a/b"] = " -", a = " -" }
        for k, v in pairs(dirs_map) do
            assert.are.equal(v, expected[k])
        end
    end)
end)
