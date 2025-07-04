# claude-cli.nvim

A Neovim plugin that connects to Claude Code CLI through the MCP Neovim server, enabling AI-powered code assistance directly in your editor.

## Prerequisites

- Neovim 0.8+
- Node.js and npm
- Claude Code CLI
- Git

## Installation

### 1. Install Claude Code CLI

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code
```

### 2. Install the Plugin

Using **lazy.nvim**:

```lua
{
  "jeremiahsmithdev/claude-cli.nvim",
  config = function()
    require("claude-cli").setup({
      socket_path = "/tmp/nvim",
      auto_start_server = false,
    })
  end,
}
```

Using **packer.nvim**:

```lua
use {
  "jeremiahsmithdev/claude-cli.nvim",
  config = function()
    require("claude-cli").setup()
  end,
}
```

## Getting Started

1. **Configure MCP server:**
   ```bash
   claude mcp add "MCP Neovim Server" -e ALLOW_SHELL_COMMANDS=true -e NVIM_SOCKET_PATH=/tmp/nvim -- npx -y mcp-neovim-server --tcp --port 3000 --host localhost
   ```

2. **Start Neovim with socket:**
   ```bash
   nvim --listen /tmp/nvim
   ```

3. **Start Claude CLI:**
   ```bash
   claude
   ```

4. **Connect in Neovim:**
   ```vim
   :ClaudeConnect
   :ClaudeStatus
   ```

## Usage

### Available Commands

- `:ClaudeConnect` - Connect to the MCP server
- `:ClaudeDisconnect` - Disconnect from the MCP server
- `:ClaudeAsk <prompt>` - Ask Claude a question
- `:ClaudeEdit <instruction>` - Edit selected text (use in visual mode)
- `:ClaudeStatus` - Check connection status

### Examples

**Ask Claude a question:**
```vim
:ClaudeAsk How do I optimize this function?
```

**Edit selected code:**
1. Select text in visual mode
2. Run `:ClaudeEdit add error handling`

**Check connection:**
```vim
:ClaudeStatus
```

## Configuration

```lua
require("claude-cli").setup({
  claude_cmd = "claude",           -- Claude CLI command
  mcp_server_host = "localhost",   -- MCP server host
  mcp_server_port = 3000,          -- MCP server port
  socket_path = "/tmp/nvim",       -- Neovim socket path
  auto_start_server = false,       -- Auto-start MCP server
  timeout = 30000,                 -- Connection timeout (ms)
})
```

## Troubleshooting

### `:ClaudeStatus` shows "Not connected"

**Step 1: Verify MCP server is running on TCP port 3000**
```bash
lsof -i :3000
```
Should show a `node` process listening on port 3000.

**Step 2: Check MCP server configuration**
```bash
claude mcp list
```
Should show `MCP Neovim Server` with `--tcp --port 3000 --host localhost` flags.

**Step 3: Test TCP connection**
```bash
nc -z localhost 3000
```
Should output "Connection to localhost port 3000 [tcp/hbci] succeeded!"

**Step 4: Check plugin configuration**
The plugin uses `127.0.0.1` not `localhost` for TCP connections. If you see "Invalid IP address" errors, verify the plugin config uses IP addresses:
```lua
require("claude-cli").setup({
  mcp_server_host = "127.0.0.1",  -- Use IP, not hostname
  mcp_server_port = 3000,
})
```

### Common Issues

**"Invalid IP address or port" error:**
- The plugin requires IP addresses, not hostnames
- Change `localhost` to `127.0.0.1` in configuration

**MCP server not listening on port 3000:**
- Remove existing MCP server: `claude mcp remove "MCP Neovim Server"`
- Re-add with TCP flags: `claude mcp add "MCP Neovim Server" -e ALLOW_SHELL_COMMANDS=true -e NVIM_SOCKET_PATH=/tmp/nvim -- npx -y mcp-neovim-server --tcp --port 3000 --host localhost`

**Connection works but commands fail:**
- Ensure Neovim socket exists: `ls -la /tmp/nvim`
- Restart Neovim with socket: `nvim --listen /tmp/nvim`

### Debug Test

Test the plugin connection:
```bash
nvim --headless -c "lua require('claude-cli').setup(); require('claude-cli.client').connect(); vim.defer_fn(function() if require('claude-cli.client').is_connected then print('SUCCESS') else print('FAILED') end; vim.cmd('quit') end, 1000)" 2>&1
```
Should output "SUCCESS".

## Development

To contribute or modify the plugin:

1. Clone the repository
2. Make your changes
3. Test with a local Neovim setup
4. Submit a pull request

## License

MIT License
