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

return M