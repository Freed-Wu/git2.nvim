---@diagnostic disable: undefined-global
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 112 113
local M = {}

local NS_ID = vim.api.nvim_create_namespace("git2.blame")
local LOADED_VAR = "git2_blame_is_loaded"

---@param bufnr integer
function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, NS_ID, 0, -1)
    pcall(vim.api.nvim_buf_del_var, bufnr, LOADED_VAR)
end

---@param bufnr integer
---@return boolean
function M.is_loaded(bufnr)
    local ok, loaded = pcall(vim.api.nvim_buf_get_var, bufnr, LOADED_VAR)
    return ok and loaded == true
end

---@param hunks table[]
---@return integer
local function get_author_width(hunks)
    local width = 6
    for _, hunk in ipairs(hunks) do
        width = math.max(width, vim.fn.strdisplaywidth(hunk.author or "unknown"))
    end
    return width
end

---@param abbrev string
---@param date string
---@param author string
---@param marker string
---@return [string, string][]
function build_virt_text(abbrev, date, author, marker)
    return {
        { ("%s %-10s"):format(abbrev, date), "Comment" },
        { " " .. author,                     "LineNr" },
        { marker,                            "NonText" },
    }
end

---@param bufnr integer
---@param hunks table[]
function M.render(bufnr, hunks)
    M.clear(bufnr)

    local nlines = vim.api.nvim_buf_line_count(bufnr)
    local author_width = get_author_width(hunks)
    for _, hunk in ipairs(hunks) do
        if hunk.start_line > nlines then
            break
        end

        local author = string.format("%-" .. author_width .. "s", hunk.author or "unknown")
        local virt_text = build_virt_text(hunk.abbrev, hunk.date or "0000-00-00", author,
            hunk.lines_in_hunk > 1 and " ┐" or "  ")

        vim.api.nvim_buf_set_extmark(bufnr, NS_ID, hunk.start_line - 1, 0, {
            virt_text = virt_text,
            virt_text_pos = "inline",
            virt_text_repeat_linebreak = true,
            priority = 1,
        })

        if hunk.lines_in_hunk > 1 then
            virt_text[3][1] = " │"
            for i = 1, hunk.lines_in_hunk - 2 do
                vim.api.nvim_buf_set_extmark(bufnr, NS_ID, hunk.start_line + i - 1, 0, {
                    virt_text = virt_text,
                    virt_text_pos = "inline",
                    virt_text_repeat_linebreak = true,
                    priority = 1,
                })
            end

            virt_text[3][1] = " ┘"
            vim.api.nvim_buf_set_extmark(bufnr, NS_ID, hunk.start_line + hunk.lines_in_hunk - 2, 0, {
                virt_text = virt_text,
                virt_text_pos = "inline",
                virt_text_repeat_linebreak = true,
                priority = 1,
            })
        end
    end

    vim.api.nvim_buf_set_var(bufnr, LOADED_VAR, true)
end

---@param hunks table[]
---@return boolean
function M.toggle(hunks)
    local bufnr = vim.api.nvim_get_current_buf()
    if M.is_loaded(bufnr) then
        M.clear(bufnr)
        return false
    end

    M.render(bufnr, hunks)
    return true
end

return M
