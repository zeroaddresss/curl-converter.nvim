local config = require("curl-converter.config")
local converter = require("curl-converter.converter")
local languages = require("curl-converter.languages")

local M = {}

local curl_command = nil
local input_buf = nil
local input_win = nil

function M.start()
  local clipboard = vim.fn.getreg("+")
  if clipboard ~= "" and clipboard:match("^%s*curl%s") then
    M._open_input_buffer(clipboard)
  else
    clipboard = vim.fn.getreg('"')
    if clipboard ~= "" and clipboard:match("^%s*curl%s") then
      M._open_input_buffer(clipboard)
    else
      M._open_input_buffer("")
    end
  end
end

function M.start_from_clipboard()
  local clipboard = vim.fn.getreg("+")
  if clipboard == "" or not clipboard:match("^%s*curl%s") then
    clipboard = vim.fn.getreg('"')
  end
  if clipboard == "" or not clipboard:match("^%s*curl%s") then
    vim.notify("[curl-converter] No curl command found in clipboard", vim.log.levels.WARN)
    return
  end
  curl_command = clipboard
  M._pick_language()
end

function M._open_input_buffer(prefill)
  input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(input_buf, "curl-converter://input")
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = input_buf })
  vim.api.nvim_set_option_value("filetype", "bash", { buf = input_buf })

  local editor_height = vim.o.lines - vim.o.cmdheight - 1
  local height = math.floor(editor_height * 0.3)
  height = math.max(height, 6)
  height = math.min(height, 16)

  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = vim.o.columns - 4,
    height = height,
    col = 2,
    row = math.floor((editor_height - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Paste curl command (press <CR> to convert, <Esc> to cancel) ",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(input_win, "winhl", "Normal:NormalFloat,FloatBorder:FloatBorder")

  if prefill and prefill ~= "" then
    local lines = vim.split(prefill, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(input_win, { #lines, #lines[#lines] })
  end

  local function confirm_input()
    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
    curl_command = table.concat(lines, "\n"):gsub("^\n*", ""):gsub("\n*$", "")
    M._close_input_buffer()
    M._pick_language()
  end

  vim.api.nvim_buf_set_keymap(input_buf, "n", "<CR>", "", {
    callback = confirm_input,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(input_buf, "i", "<CR>", "", {
    callback = confirm_input,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(input_buf, "n", "<Esc>", "", {
    callback = function()
      M._close_input_buffer()
    end,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(input_buf, "i", "<Esc>", "", {
    callback = function()
      M._close_input_buffer()
    end,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_set_current_win(input_win)
  vim.cmd("startinsert!")
end

function M._close_input_buffer()
  pcall(vim.api.nvim_win_close, input_win, true)
  pcall(vim.api.nvim_buf_delete, input_buf, { force = true })
  input_win = nil
  input_buf = nil
end

local function format_language_display(group_name, item_label)
  if item_label == group_name then
    return item_label
  end
  if item_label:sub(1, #group_name) == group_name then
    local rest = item_label:sub(#group_name + 1):gsub("^%s*%+%s*", "")
    if rest ~= "" then
      return group_name .. " (" .. rest .. ")"
    end
  end
  return item_label
end

function M._pick_language()
  local items = {}
  for _, group in ipairs(languages.groups) do
    for _, item in ipairs(group.items) do
      items[#items + 1] = {
        display = format_language_display(group.name, item.label),
        value = item.value,
        label = item.label,
      }
    end
  end

  local ok, _ = pcall(require, "telescope")

  if ok then
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local sorters = require("telescope.sorters")
    local actions = require("telescope.actions")
    local actions_state = require("telescope.actions.state")

    pickers.new({}, {
      prompt_title = " Select target language ",
      finder = finders.new_table({
        results = items,
        entry_maker = function(item)
          return {
            value = item.value,
            display = item.display,
            ordinal = item.label,
          }
        end,
      }),
      sorter = sorters.get_fzy_sorter(),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = actions_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            M._convert_and_show(selection.value)
          end
        end)
        return true
      end,
    }):find()
    return
  end

  M._show_language_picker(languages.groups, function(value)
    if value then
      M._convert_and_show(value)
    end
  end)
end

function M._show_language_picker(groups, on_choice)
  local items = {}
  for _, group in ipairs(groups) do
    items[#items + 1] = { type = "group", label = group.name }
    for _, item in ipairs(group.items) do
      items[#items + 1] = { type = "item", label = item.label, value = item.value }
    end
  end

  if #items == 0 then
    on_choice(nil)
    return
  end

  local selected = 1
  for i, item in ipairs(items) do
    if item.type == "item" then
      selected = i
      break
    end
  end

  local function render()
    local lines = {}
    for _, item in ipairs(items) do
      lines[#lines + 1] = (item.type == "group") and ("  " .. item.label) or ("    " .. item.label)
    end
    return lines
  end

  local function prev_selectable(i)
    for idx = i - 1, 1, -1 do
      if items[idx].type == "item" then return idx end
    end
    return i
  end

  local function next_selectable(i)
    for idx = i + 1, #items do
      if items[idx].type == "item" then return idx end
    end
    return i
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, render())
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local editor_height = vim.o.lines - vim.o.cmdheight - 1
  local editor_width = vim.o.columns

  local lines = render()
  local max_len = 0
  for _, l in ipairs(lines) do
    if #l > max_len then max_len = #l end
  end

  local win_width = math.min(max_len + 6, math.floor(editor_width * 0.7))
  win_width = math.max(win_width, 50)

  local total_lines = #lines
  local win_height = math.min(total_lines + 2, math.floor(editor_height * 0.5))
  win_height = math.max(win_height, math.min(total_lines, 10))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    col = math.floor((editor_width - win_width) / 2),
    row = math.floor((editor_height - win_height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Select target language ",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat,FloatBorder:FloatBorder")
  vim.api.nvim_win_set_option(win, "cursorline", true)

  local function close()
    pcall(vim.api.nvim_win_close, win, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end

  local function update_cursor()
    vim.api.nvim_win_set_cursor(win, { selected, 0 })
  end

  vim.api.nvim_buf_set_keymap(buf, "n", "j", "", {
    callback = function()
      local new = next_selectable(selected)
      if new ~= selected then selected = new; update_cursor() end
    end, noremap = true, silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "k", "", {
    callback = function()
      local new = prev_selectable(selected)
      if new ~= selected then selected = new; update_cursor() end
    end, noremap = true, silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "<Down>", "", {
    callback = function()
      local new = next_selectable(selected)
      if new ~= selected then selected = new; update_cursor() end
    end, noremap = true, silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "<Up>", "", {
    callback = function()
      local new = prev_selectable(selected)
      if new ~= selected then selected = new; update_cursor() end
    end, noremap = true, silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
    callback = function() close(); on_choice(items[selected].value) end,
    noremap = true, silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
    callback = function() close(); on_choice(nil) end,
    noremap = true, silent = true,
  })

  update_cursor()
  vim.api.nvim_set_current_win(win)
end

function M._convert_and_show(language)
  if not curl_command or curl_command == "" then
    vim.notify("[curl-converter] No curl command provided", vim.log.levels.ERROR)
    return
  end

  vim.notify("[curl-converter] Converting to " .. languages.resolve_label(language) .. "...", vim.log.levels.INFO)

  converter.convert_async(curl_command, language, function(code, err, warnings)
    if err then
      vim.notify("[curl-converter] " .. err, vim.log.levels.ERROR)
      return
    end
    vim.schedule(function()
      M._show_output(code, language, warnings)
    end)
  end)
end

function M._show_output(code, language, warnings)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

  local lang_ft = language:gsub("-.+", "")
  local ft_map = {
    python = "python",
    javascript = "javascript",
    node = "javascript",
    go = "go",
    rust = "rust",
    php = "php",
    ruby = "ruby",
    java = "java",
    csharp = "cs",
    swift = "swift",
    kotlin = "kotlin",
    dart = "dart",
    lua = "lua",
    julia = "julia",
    r = "r",
    c = "c",
    json = "json",
    ansible = "yaml",
    powershell = "powershell",
    perl = "perl",
    objc = "objc",
    ocaml = "ocaml",
    elixir = "elixir",
    clojure = "clojure",
    cfml = "cfml",
    har = "json",
    http = "http",
    wget = "bash",
    httpie = "bash",
    matlab = "matlab",
  }
  vim.api.nvim_set_option_value("syntax", ft_map[lang_ft] or "", { buf = buf })

  local lines = vim.split(code, "\n", { plain = true })

  if warnings and #warnings > 0 then
    table.insert(lines, "")
    table.insert(lines, string.rep("─", 40))
    table.insert(lines, " Warnings:")
    for _, w in ipairs(warnings) do
      if type(w) == "table" then
        table.insert(lines, "  • " .. (w[1] or "") .. ": " .. (w[2] or ""))
      else
        table.insert(lines, "  • " .. tostring(w))
      end
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", lang_ft, { buf = buf })

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight - 1
  local win_width = math.floor(editor_width * config.options.output_window.width)
  local win_height = math.floor(editor_height * config.options.output_window.height)
  local win_col = math.floor((editor_width - win_width) / 2)
  local win_row = math.floor((editor_height - win_height) / 2)

  local lang_label = languages.resolve_label(language)
  local title = " curl-converter (" .. lang_label .. ") · y:yank  r:reselect  q:close "

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    col = win_col,
    row = win_row,
    style = "minimal",
    border = config.options.output_window.border,
    title = title,
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat,FloatBorder:FloatBorder")
  vim.api.nvim_win_set_option(win, "cursorline", true)

  local km = config.options.keymaps

  local function close()
    pcall(vim.api.nvim_win_close, win, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end

  vim.api.nvim_buf_set_keymap(buf, "n", km.close, "", {
    callback = close, noremap = true, silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
    callback = close, noremap = true, silent = true,
  })

  local function yank_and_close()
    vim.fn.setreg('"', code)
    pcall(vim.fn.setreg, "+", code)
    close()
  end

  vim.api.nvim_buf_set_keymap(buf, "n", km.yank, "", {
    callback = yank_and_close,
    noremap = true, silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "Y", "", {
    callback = yank_and_close,
    noremap = true, silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", km.reselect, "", {
    callback = function()
      close()
      M._pick_language()
    end,
    noremap = true, silent = true,
  })

  vim.api.nvim_set_current_win(win)
end

return M
