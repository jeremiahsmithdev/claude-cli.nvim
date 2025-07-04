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
npm install -g @anthropic-ai/claude-cli

# Or using pip
pip install claude-cli
```

### 2. Install MCP Neovim Server

```bash
npm install -g @bigcodegen/mcp-neovim-server
```

### 3. Install the Plugin

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

## Setup Instructions

### Step 1: Start Neovim with Socket

Start Neovim with a socket for the MCP server to connect to:

```bash
nvim --listen /tmp/nvim
```

### Step 2: Start MCP Neovim Server

In a separate terminal, start the MCP server:

```bash
npx @bigcodegen/mcp-neovim-server --socket /tmp/nvim
```

### Step 3: Start Claude Code CLI with MCP

In another terminal, start Claude Code CLI and connect it to the MCP server:

```bash
claude --mcp-server http://localhost:3000
```

### Step 4: Connect in Neovim

In Neovim, connect to the MCP server:

```vim
:ClaudeConnect
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

### Connection Issues

1. **Check if Neovim socket exists:**
   ```bash
   ls -la /tmp/nvim
   ```

2. **Verify MCP server is running:**
   ```bash
   curl http://localhost:3000/health
   ```

3. **Check Claude CLI connection:**
   ```bash
   claude --version
   ```

### Common Problems

- **Socket not found**: Ensure Neovim was started with `--listen /tmp/nvim`
- **MCP server not responding**: Restart the MCP server
- **Claude CLI not connected**: Check your Claude CLI authentication and MCP connection

## Development

To contribute or modify the plugin:

1. Clone the repository
2. Make your changes
3. Test with a local Neovim setup
4. Submit a pull request

## License

MIT License
