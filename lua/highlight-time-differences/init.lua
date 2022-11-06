local M = {}

function M.HighlightTimeDifferences()
    local buf = 0
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local time_pattern = "^.*(%d%d):(%d%d):(%d%d).(%d%d%d)"

    local function extract_time_from_line(line)
        local start_pos, end_pos, h, m, s, ms = line:find(time_pattern)
        if h == nil or m == nil or s == nil or ms == nil then
            return nil
        end
        return start_pos, end_pos, ms + 1000 * s + 60 * 1000 * m + 60 * 60 * 1000 * h
    end

    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    local nsid = vim.api.nvim_create_namespace("highlight-time-differences")
    local last_time = nil
    for line_nr in pairs(lines) do
        local time_start_pos, time_end_pos, current_line_time = extract_time_from_line(lines[line_nr])

        if current_line_time == nil then
            goto continue
        end

        local diff = 0
        if last_time ~= nil then
            diff = current_line_time - last_time
        end

        local highlight_group = nil
        if diff >= 1000 * 60 then -- one minute
            highlight_group = "DiagnosticError"
        elseif diff >= 1000 * 10 then -- 10 seconds
            highlight_group = "DiagnosticWarn"
        elseif diff >= 1000 then -- 1 second
            highlight_group = "DiagnosticInfo"
        elseif diff >= 100 then -- 100 ms
            highlight_group = "DiagnosticHint"
        elseif diff < 0 then
            highlight_group = "Error"
        end

        if highlight_group ~= nil then
            vim.api.nvim_buf_add_highlight(buf, nsid, highlight_group, line_nr - 1, time_start_pos - 1, time_end_pos)
        end

        last_time = current_line_time
        ::continue::
    end
end

return M
