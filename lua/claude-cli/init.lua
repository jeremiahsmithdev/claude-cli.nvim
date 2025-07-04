local M = {}

M.config = {
  claude_cmd = "claude",
  mcp_server_host = "127.0.0.1",
  mcp_server_port = 3000,
  auto_start_server = false,
  socket_path = "/tmp/nvim",
  timeout = 30000,
}

local function setup_commands()
  vim.api.nvim_create_user_command("ClaudeConnect", function()
    require("claude-cli.client").connect()
  end, {})

  vim.api.nvim_create_user_command("ClaudeDisconnect", function()
    require("claude-cli.client").disconnect()
  end, {})

  vim.api.nvim_create_user_command("ClaudeAsk", function(opts)
    require("claude-cli.client").ask(opts.args)
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("ClaudeStatus", function()
    require("claude-cli.client").status()
  end, {})

  vim.api.nvim_create_user_command("ClaudeEdit", function(opts)
    require("claude-cli.client").edit_selection(opts.args)
  end, { nargs = "*", range = true })

  vim.api.nvim_create_user_command("ClaudeSend", function(opts)
    require("claude-cli.client").send_command(opts.args)
  end, { nargs = "*" })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_commands()
  
  if M.config.auto_start_server then
    require("claude-cli.server").start()
  end
end

return M