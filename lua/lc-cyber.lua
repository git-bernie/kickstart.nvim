-- LoanConnect ID Encoder/Decoder for Neovim
-- Usage:
--   :lua require('lc-cyber').decode('encoded_string')
--   :lua require('lc-cyber').encode(123456)
--   :lua require('lc-cyber').decode_selection()  -- decode visual selection
--   :lua require('lc-cyber').encode_selection()  -- encode visual selection
--   :lua require('lc-cyber').decode_word()       -- decode word under cursor (smart extraction)
--   :lua require('lc-cyber').decode_word_to_clipboard()  -- same but copy to clipboard
--
-- Keybindings (add to your config):
--   vim.keymap.set('n', '<leader>cd', require('lc-cyber').decode_word, { desc = 'Decode LC ID under cursor' })
--   vim.keymap.set('n', '<leader>cy', require('lc-cyber').decode_word_to_clipboard, { desc = 'Decode LC ID to clipboard' })
--   vim.keymap.set('v', '<leader>cd', require('lc-cyber').decode_selection, { desc = 'Decode LC ID selection' })
--   vim.keymap.set('v', '<leader>cy', require('lc-cyber').decode_selection_to_clipboard, { desc = 'Decode LC ID to clipboard' })
--   vim.keymap.set('n', '<leader>ce', require('lc-cyber').encode_word, { desc = 'Encode LC ID under cursor' })

local M = {}

-- Path to the lc-cyber script
local script_path = vim.fn.expand('~/bin/lc-cyber')

---Run lc-cyber command and return result
---@param action string
---@param value string
---@return string|nil result
---@return string|nil error
local function run_lc_cyber(action, value)
    local cmd = string.format('%s %s %q 2>&1', script_path, action, value)
    local handle = io.popen(cmd)
    if not handle then
        return nil, 'Failed to run lc-cyber'
    end
    local result = handle:read('*a')
    local success = handle:close()
    result = result:gsub('%s+$', '') -- trim trailing whitespace

    if success and result ~= '' and not result:match('^Error:') then
        return result, nil
    else
        return nil, result or 'Unknown error'
    end
end

---Get base64url-encoded ID under cursor
---Base64url uses: A-Z, a-z, 0-9, -, _ (no padding = in our IDs)
---Stops at boundaries: / " ' & ? space and other delimiters
---Handles query strings: ?id=<encoded>& - cursor on = jumps to value
---@return string The extracted word, or empty string if not found or too short
local function get_encoded_id_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-indexed column

    if col >= #line then
        return ''
    end

    -- Get character at cursor (Lua strings are 1-indexed)
    local char = line:sub(col + 1, col + 1)

    -- If cursor is on '=', move right to find the value (handles ?id=<encoded>)
    if char == '=' then
        col = col + 1
        if col >= #line then
            return ''
        end
        char = line:sub(col + 1, col + 1)
    end

    -- Check if cursor is on a valid base64url character
    if not char:match('[A-Za-z0-9_-]') then
        return ''
    end

    -- Expand left from cursor position
    local start_col = col
    while start_col > 0 do
        local prev_char = line:sub(start_col, start_col)
        if prev_char:match('[A-Za-z0-9_-]') then
            start_col = start_col - 1
        else
            break
        end
    end

    -- Expand right from cursor position
    local end_col = col + 1
    while end_col < #line do
        local next_char = line:sub(end_col + 1, end_col + 1)
        if next_char:match('[A-Za-z0-9_-]') then
            end_col = end_col + 1
        else
            break
        end
    end

    -- Extract the word (Lua strings are 1-indexed)
    local word = line:sub(start_col + 1, end_col)

    -- Base64url encoded IDs are typically 40-50 chars, but allow some range
    -- Minimum sanity check: at least 10 chars to avoid matching short words
    if #word < 10 then
        return ''
    end

    return word
end

---Decode an encoded LoanConnect ID
---@param encoded string The encoded value
---@return string|nil decoded The decoded ID or nil on error
function M.decode(encoded)
    local result, err = run_lc_cyber('decode', encoded)
    if result then
        print('Decoded: ' .. result)
        return result
    else
        print('Decode error: ' .. (err or 'unknown'))
        return nil
    end
end

---Encode a raw ID
---@param raw string|number The raw ID
---@return string|nil encoded The encoded value or nil on error
function M.encode(raw)
    local result, err = run_lc_cyber('encode', tostring(raw))
    if result then
        print('Encoded: ' .. result)
        return result
    else
        print('Encode error: ' .. (err or 'unknown'))
        return nil
    end
end

---Get visual selection text
---@return string
local function get_visual_selection()
    -- Save the current register
    local saved_reg = vim.fn.getreg('v')
    local saved_regtype = vim.fn.getregtype('v')

    -- Yank the visual selection into register v
    vim.cmd('noau normal! "vy')
    local selection = vim.fn.getreg('v')

    -- Restore the register
    vim.fn.setreg('v', saved_reg, saved_regtype)

    return selection:gsub('%s+', '') -- trim whitespace
end

---Decode the visual selection and show result
function M.decode_selection()
    local selection = get_visual_selection()
    if selection == '' then
        print('No selection')
        return
    end
    M.decode(selection)
end

---Decode the visual selection, show result, and copy to clipboard
function M.decode_selection_to_clipboard()
    local selection = get_visual_selection()
    if selection == '' then
        print('No selection')
        return
    end
    local result, err = run_lc_cyber('decode', selection)
    if result then
        -- Store in register c and clipboard
        vim.fn.setreg('c', result)
        vim.fn.setreg('+', result)
        print('Decoded: ' .. result .. ' (copied to clipboard)')
        return result
    else
        vim.api.nvim_echo({{'Could not decode selection', 'ErrorMsg'}}, true, {})
        return nil
    end
end

---Encode the visual selection and show result
function M.encode_selection()
    local selection = get_visual_selection()
    if selection == '' then
        print('No selection')
        return
    end
    M.encode(selection)
end

---Decode and replace the visual selection
function M.decode_replace()
    local selection = get_visual_selection()
    if selection == '' then
        print('No selection')
        return
    end
    local result, err = run_lc_cyber('decode', selection)
    if result then
        -- Replace the selection with the decoded value
        vim.cmd('noau normal! gv"_c' .. result)
        print('Replaced with: ' .. result)
    else
        print('Decode error: ' .. (err or 'unknown'))
    end
end

---Encode and replace the visual selection
function M.encode_replace()
    local selection = get_visual_selection()
    if selection == '' then
        print('No selection')
        return
    end
    local result, err = run_lc_cyber('encode', selection)
    if result then
        -- Replace the selection with the encoded value
        vim.cmd('noau normal! gv"_c' .. result)
        print('Replaced with: ' .. result)
    else
        print('Encode error: ' .. (err or 'unknown'))
    end
end

---Decode word under cursor - show result in command line
---Uses smart extraction for base64url IDs first, falls back to cWORD
function M.decode_word()
    -- Try smart extraction for base64url IDs first
    local word = get_encoded_id_under_cursor()

    -- Fall back to cWORD with cleanup if smart extraction fails
    if word == '' then
        word = vim.fn.expand('<cWORD>')
        -- Clean up common URL characters that might be captured
        word = word:gsub('[%[%](){}<>,:;]', '')
    end

    local result, err = run_lc_cyber('decode', word)
    if result then
        -- Store in register c for easy pasting
        vim.fn.setreg('c', result)
        vim.api.nvim_echo({{'Decoded: ' .. result .. ' (stored in @c)', 'MoreMsg'}}, true, {})
        return result
    else
        vim.api.nvim_echo({{'Could not decode: ' .. word, 'ErrorMsg'}}, true, {})
        return nil
    end
end

---Decode word under cursor - copy to clipboard
---Uses smart extraction for base64url IDs first, falls back to cWORD
function M.decode_word_to_clipboard()
    -- Try smart extraction for base64url IDs first
    local word = get_encoded_id_under_cursor()

    -- Fall back to cWORD with cleanup if smart extraction fails
    if word == '' then
        word = vim.fn.expand('<cWORD>')
        -- Clean up common URL characters that might be captured
        word = word:gsub('[%[%](){}<>,:;]', '')
    end

    local result, err = run_lc_cyber('decode', word)
    if result then
        -- Store in register c and clipboard
        vim.fn.setreg('c', result)
        vim.fn.setreg('+', result)
        vim.api.nvim_echo({{'Decoded: ' .. result .. ' (copied to clipboard)', 'MoreMsg'}}, true, {})
        return result
    else
        vim.api.nvim_echo({{'Could not decode: ' .. word, 'ErrorMsg'}}, true, {})
        return nil
    end
end

---Encode word under cursor - show result in command line
function M.encode_word()
    local word = vim.fn.expand('<cword>')
    local result, err = run_lc_cyber('encode', word)
    if result then
        -- Store in register c for easy pasting
        vim.fn.setreg('c', result)
        vim.api.nvim_echo({{'Encoded: ' .. result .. ' (stored in @c)', 'MoreMsg'}}, true, {})
        return result
    else
        vim.api.nvim_echo({{'Could not encode: ' .. word, 'ErrorMsg'}}, true, {})
        return nil
    end
end

return M
