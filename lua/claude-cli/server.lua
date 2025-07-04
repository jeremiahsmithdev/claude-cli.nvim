local M = {}

local uv = vim.loop
local config = require("claude-cli").config

M.server_job = nil

local function log(message, level)
  vim.notify("[Claude CLI Server] " .. message, level or vim.log.levels.INFO)
end

function M.start()
  if M.server_job then
    log("MCP server already running")
    return
  end

  local nvim_socket = config.socket_path
  local cmd = {
    "npx", "@bigcodegen/mcp-neovim-server",
    "--socket", nvim_socket
  }

  log("Starting MCP server...")
  
  M.server_job = uv.spawn(cmd[1], {
    args = vim.list_slice(cmd, 2),
    stdio = { nil, nil, nil }
  }, function(code, signal)
    M.server_job = nil
    if code == 0 then
      log("MCP server stopped normally")
    else
      log("MCP server stopped with code " .. code, vim.log.levels.WARN)
    end
  end)

  if not M.server_job then
    log("Failed to start MCP server", vim.log.levels.ERROR)
    return false
  end

  log("MCP server started with PID: " .. M.server_job.pid)
  return true
end

function M.stop()
  if not M.server_job then
    log("No MCP server running")
    return
  end

  M.server_job:kill()
  M.server_job = nil
  log("MCP server stopped")
end

function M.restart()
  M.stop()
  vim.defer_fn(function()
    M.start()
  end, 1000)
end

return M