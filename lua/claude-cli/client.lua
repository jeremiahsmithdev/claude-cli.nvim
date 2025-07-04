local M = {}

local uv = vim.loop
local config = require("claude-cli").config

M.connection = nil
M.is_connected = false

local function log(message, level)
  vim.notify("[Claude CLI] " .. message, level or vim.log.levels.INFO)
end

local function send_request(method, params)
  if not M.is_connected then
    log("Not connected to Claude CLI", vim.log.levels.ERROR)
    return nil
  end

  local request = {
    jsonrpc = "2.0",
    method = method,
    params = params or {},
    id = vim.fn.localtime()
  }

  local json_request = vim.json.encode(request)
  local success, err = pcall(function()
    M.connection:write(json_request .. "\n")
  end)

  if not success then
    log("Failed to send request: " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end

  return request.id
end

function M.connect()
  if M.is_connected then
    log("Already connected to Claude CLI")
    return
  end

  local tcp = uv.new_tcp()
  tcp:connect(config.mcp_server_host, config.mcp_server_port, function(err)
    if err then
      log("Failed to connect to MCP server: " .. err, vim.log.levels.ERROR)
      return
    end

    M.connection = tcp
    M.is_connected = true
    log("Connected to Claude CLI via MCP server")

    tcp:read_start(function(err, data)
      if err then
        log("Connection error: " .. err, vim.log.levels.ERROR)
        M.disconnect()
        return
      end

      if data then
        local success, response = pcall(vim.json.decode, data)
        if success then
          M.handle_response(response)
        end
      else
        log("Connection closed by server")
        M.disconnect()
      end
    end)
  end)
end

function M.disconnect()
  if M.connection then
    M.connection:close()
    M.connection = nil
  end
  M.is_connected = false
  log("Disconnected from Claude CLI")
end

function M.handle_response(response)
  if response.result then
    if response.result.content then
      vim.schedule(function()
        local lines = vim.split(response.result.content, "\n")
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
        vim.api.nvim_win_set_buf(0, buf)
      end)
    end
  elseif response.error then
    log("Error: " .. tostring(response.error.message), vim.log.levels.ERROR)
  end
end

function M.ask(prompt)
  if not prompt or prompt == "" then
    log("Please provide a prompt", vim.log.levels.WARN)
    return
  end

  local context = {
    current_file = vim.api.nvim_buf_get_name(0),
    cursor_pos = vim.api.nvim_win_get_cursor(0),
    working_dir = vim.fn.getcwd(),
  }

  send_request("claude/ask", {
    prompt = prompt,
    context = context
  })
end

function M.edit_selection(instruction)
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local selected_text = table.concat(lines, "\n")

  if not instruction or instruction == "" then
    instruction = "Improve this code"
  end

  send_request("claude/edit", {
    text = selected_text,
    instruction = instruction,
    file_path = vim.api.nvim_buf_get_name(0),
    start_line = start_line,
    end_line = end_line
  })
end

function M.status()
  if M.is_connected then
    log("Connected to Claude CLI MCP server at " .. config.mcp_server_host .. ":" .. config.mcp_server_port)
  else
    log("Not connected to Claude CLI")
  end
end

function M.send_command(command)
  if not command or command == "" then
    log("Please provide a command to send", vim.log.levels.WARN)
    return
  end

  -- Try to send via tmux first (most reliable for Claude CLI)
  local tmux_success = M.send_via_tmux(command)
  if tmux_success then
    log("Sent command to Claude CLI via tmux: " .. command)
    return
  end

  -- Fallback to TTY method
  M.send_via_tty(command)
end

function M.send_via_tmux(command)
  -- Look for Claude CLI in tmux sessions
  local handle = io.popen("tmux list-sessions 2>/dev/null | grep claude")
  local session_line = handle:read("*l")
  handle:close()

  if not session_line then
    return false
  end

  -- Extract session name (everything before the colon)
  local session_name = session_line:match("^([^:]+):")
  if not session_name then
    return false
  end

  -- Find the pane with node (Claude CLI)
  local pane_handle = io.popen("tmux list-panes -t " .. session_name .. " -F '#{pane_id}: #{pane_current_command}' 2>/dev/null | grep node")
  local pane_line = pane_handle:read("*l")
  pane_handle:close()

  if not pane_line then
    return false
  end

  -- Extract pane ID
  local pane_id = pane_line:match("^([^:]+):")
  if not pane_id then
    return false
  end

  -- Send the command via tmux with delayed Enter (Test 11 approach)
  -- First send the text, then send Enter after a delay to ensure proper context
  local escaped_command = command:gsub("'", "'\"'\"'")
  
  -- Send text first
  local text_cmd = string.format("tmux send-keys -t %s '%s'", pane_id, escaped_command)
  os.execute(text_cmd)
  
  -- Small delay to separate text input from submission (like Test 11)
  os.execute("sleep 0.1")
  
  -- Send Enter as a separate action
  local enter_cmd = string.format("tmux send-keys -t %s Enter", pane_id)
  local result = os.execute(enter_cmd)
  
  return result == 0
end

function M.send_via_tty(command)
  -- Find the Claude CLI process
  local handle = io.popen("ps aux | grep -E '^[^[:space:]]+[[:space:]]+[0-9]+.*claude[[:space:]]*$' | grep -v grep | head -1 | awk '{print $2}'")
  local claude_pid = handle:read("*l")
  handle:close()

  if not claude_pid or claude_pid == "" then
    log("Claude CLI process not found", vim.log.levels.ERROR)
    M.send_command_via_file(command)
    return
  end

  -- Try to send the command to Claude CLI's stdin via the TTY
  local tty_handle = io.popen("lsof -p " .. claude_pid .. " | grep -E 'tty|pts' | head -1 | awk '{print $NF}'")
  local tty_path = tty_handle:read("*l")
  tty_handle:close()

  if tty_path and tty_path ~= "" then
    -- Try to write to the TTY
    local success, err = pcall(function()
      local tty_file = io.open(tty_path, "w")
      if tty_file then
        tty_file:write(command .. "\n")
        tty_file:close()
        log("Sent command to Claude CLI via TTY: " .. command)
      else
        error("Could not open TTY")
      end
    end)

    if not success then
      log("Failed to send to TTY: " .. tostring(err), vim.log.levels.ERROR)
      M.send_command_via_file(command)
    end
  else
    log("Could not find Claude CLI TTY", vim.log.levels.ERROR)
    M.send_command_via_file(command)
  end
end

function M.send_command_via_file(command)
  -- Create a temporary file with the command
  local temp_file = "/tmp/claude_nvim_command.txt"
  local file = io.open(temp_file, "w")
  if file then
    file:write(command .. "\n")
    file:close()
    log("Command written to " .. temp_file .. " - you can copy/paste it to Claude CLI")
  else
    log("Failed to write command to temporary file", vim.log.levels.ERROR)
  end
end

return M