local M = {}

-- %t is a single character that specifies the type. One of "e" (error), "w" (warning), "i" (info), "n" (note)
-- %f is the file name
-- %l is the line number
local vim_error_format = "%m:%t:%f:%l"
local error_template = "'%s ms:%s:%s:%d'"
local highlight_groups = { "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint" }
local quickfix_types = { "e", "w", "i", "n" }

local namespace_id = nil

local function add_quickfix_entry(quickfixes, type, file_name, line, diff)
    local quickfix = { diff, type, file_name, line }
    table.insert(quickfixes, quickfix)
end

function M.HighlightTimeDifferencesClear(start_line, end_line)
    if namespace_id ~= nil then
        local buf = 0
        vim.api.nvim_buf_clear_namespace(buf, namespace_id, start_line - 1, end_line + 1)
    end
end

function M.HighlightTimeDifferences(start_line, end_line, thresholds)
    if #thresholds > 4 then
        error("Only up to 4 threshold numbers are supported")
    end
    for i, t in ipairs(thresholds) do
        thresholds[i] = tonumber(t)
        if thresholds[i] == nil then
            error("Threshold must be a number!")
        end
    end

    if #thresholds == 0 then
        thresholds = { 1000 * 60 } -- one minute
    end


    local buf = 0
    local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
    local time_pattern = "^.*(%d%d):(%d%d):(%d%d).(%d%d%d)"
    local file_name = vim.api.nvim_buf_get_name(0) or ""
    local quickfixes = {}

    local function extract_time_from_line(line)
        local start_pos, end_pos, h, m, s, ms = line:find(time_pattern)
        if h == nil or m == nil or s == nil or ms == nil then
            return nil
        end
        return start_pos, end_pos, ms + 1000 * s + 60 * 1000 * m + 60 * 60 * 1000 * h
    end

    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    namespace_id = vim.api.nvim_create_namespace("highlight-time-differences")
    local last_time = nil
    for relative_line_nr in pairs(lines) do
        local line_nr = start_line - 1 + relative_line_nr
        local time_start_pos, time_end_pos, current_line_time = extract_time_from_line(lines[relative_line_nr])

        if current_line_time == nil then
            goto continue
        end

        local diff = 0
        if last_time ~= nil then
            diff = current_line_time - last_time
        end

        local highlight_group = nil
        local quickfix_type = nil

        if diff < 0 then
            highlight_group = "Error"
        else
            for i, t in ipairs(thresholds) do
                if highlight_group == nil and diff >= t then
                    highlight_group = highlight_groups[i]
                    quickfix_type = quickfix_types[i]
                end
            end
        end

        if highlight_group ~= nil then
            vim.api.nvim_buf_add_highlight(buf, namespace_id, highlight_group, line_nr - 1, time_start_pos - 1,
                time_end_pos)
        end

        if quickfix_type ~= nil then
            add_quickfix_entry(quickfixes, quickfix_type, file_name, line_nr, diff)
        end

        last_time = current_line_time
        ::continue::
    end

    table.sort(quickfixes, function(a, b) return a[1] > b[1] end)

    for i, v in ipairs(quickfixes) do
        quickfixes[i] = string.format(error_template, v[1], v[2], v[3], v[4])
    end

    if #quickfixes > 0 then
        vim.api.nvim_command(string.format("set errorformat=%s", vim_error_format))
        vim.api.nvim_command(string.format("cexpr [%s]", table.concat(quickfixes, ",")))
    end
end

return M
