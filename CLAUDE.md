# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim plugin that connects to Claude Code CLI through the MCP (Model Context Protocol) Neovim server. It enables AI-powered code assistance directly in Neovim by establishing a communication bridge between the editor and Claude CLI.

## Architecture

### Core Components

- **lua/claude-cli/init.lua** - Main plugin initialization and configuration management
- **lua/claude-cli/client.lua** - Handles JSON-RPC communication with the MCP server
- **lua/claude-cli/server.lua** - Manages the MCP Neovim server lifecycle
- **plugin/claude-cli.lua** - Plugin loading and cleanup autocmds

### Communication Flow

1. Plugin connects to MCP server via TCP (localhost:3000 by default)
2. Uses JSON-RPC protocol for sending requests to Claude CLI
3. Responses are displayed in new buffers with markdown formatting
4. Selected text can be edited by sending context to Claude with instructions

## Development Commands

### Testing the Plugin

```bash
# Start Neovim with socket for MCP server connection
nvim --listen /tmp/nvim

# In another terminal, ensure MCP server is configured
claude mcp add "MCP Neovim Server" -e ALLOW_SHELL_COMMANDS=true -e NVIM_SOCKET_PATH=/tmp/nvim -- npx -y mcp-neovim-server

# Start Claude CLI
claude
```

### Plugin Commands

Once loaded in Neovim:
- `:ClaudeConnect` - Establish connection to MCP server
- `:ClaudeDisconnect` - Close connection
- `:ClaudeAsk <prompt>` - Send question to Claude
- `:ClaudeEdit <instruction>` - Edit selected text (visual mode)
- `:ClaudeStatus` - Check connection status

## Configuration Structure

Default configuration in `init.lua`:
```lua
{
  claude_cmd = "claude",           -- Claude CLI command
  mcp_server_host = "localhost",   -- MCP server host
  mcp_server_port = 3000,          -- MCP server port
  auto_start_server = false,       -- Auto-start MCP server
  socket_path = "/tmp/nvim",       -- Neovim socket path
  timeout = 30000,                 -- Connection timeout (ms)
}
```

## Key Implementation Details

### JSON-RPC Protocol
- Uses vim.json.encode/decode for message serialization
- Request format includes jsonrpc, method, params, and id fields
- Responses handled asynchronously with vim.schedule for UI updates

### Connection Management
- TCP connection via vim.loop (libuv)
- Connection state tracked in client.lua
- Automatic cleanup on VimLeavePre event

### Context Passing
- Current file path, cursor position, and working directory sent with requests
- Selected text and line numbers included for edit operations

## Dependencies

- Neovim 0.8+
- Node.js and npm (for MCP server)
- Claude Code CLI
- @bigcodegen/mcp-neovim-server package