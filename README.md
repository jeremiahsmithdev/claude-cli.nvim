# claude-cli.nvim

A Neovim plugin that connects to Claude Code CLI through the MCP Neovim server, enabling AI-powered code assistance directly in your editor.

## Prerequisites

- Neovim 0.8+
- Node.js and npm
- Claude Code CLI
- Git

## Installation

### 1. Install Claude Code CLI

Follow the official installation guide at https://claude.ai/code

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

### Prerequisites Setup

1. **Configure MCP server:**
   ```bash
   claude mcp add "MCP Neovim Server" -e NVIM_SOCKET_PATH=/tmp/nvim -- npx -y mcp-neovim-server
   ```

2. **Start Neovim with socket:**
   ```bash
   nvim --listen /tmp/nvim
   ```

3. **Start Claude CLI in a tmux session:**
   ```bash
   tmux new-session -s claude-cli
   claude
   ```
   
   **Important:** The plugin requires Claude CLI to be running in a tmux session for `:ClaudeSend` to work properly.

## Usage
### Available Commands

- `:ClaudeConnect` - Connect to the MCP server
- `:ClaudeDisconnect` - Disconnect from the MCP server
- `:ClaudeStatus` - Check connection status
- `:ClaudeSend <message>` - Send a message directly to Claude CLI and automatically submit it
  - Requires Claude CLI to be running in a tmux session
  - Messages are automatically submitted after a 0.1s delay
  - Example: `:ClaudeSend How do I implement a binary search?`

### Examples

**Connect to Claude CLI:**
```vim
:ClaudeConnect
:ClaudeStatus
```

**Send a message to Claude:**
```vim
:ClaudeSend What is the time complexity of this algorithm?
:ClaudeSend Explain how this React hook works
:ClaudeSend Help me debug this error message
```

**Disconnect when done:**
```vim
:ClaudeDisconnect
```

The message will appear in your Claude CLI terminal and be automatically submitted.

## Configuration

```lua
require("claude-cli").setup({
  -- Currently no configuration is needed for basic functionality
  -- The plugin will automatically find your Claude CLI tmux session
})
```

## Troubleshooting

### `:ClaudeSend` not working

**Step 1: Ensure Claude CLI is running in tmux**
```bash
tmux list-sessions | grep claude
```
You should see a session with "claude" in the name.

**Step 2: Verify Claude CLI is the active process**
```bash
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' | grep claude
```
Look for a pane running `node` (the Claude CLI process).

**Step 3: Test manual message sending**
```bash
tmux send-keys -t <session>:<pane> "test message" Enter
```
Replace `<session>:<pane>` with your Claude CLI session and pane.

### Common Issues

**"Claude CLI process not found" error:**
- Make sure Claude CLI is running in a tmux session
- The session name should contain "claude" (e.g., `claude-cli`, `claude-session`)

**Messages appear but don't submit:**
- The plugin uses a 0.1s delay between typing and submission
- If messages still don't submit, try increasing the delay in the code

**Nothing happens when using `:ClaudeSend`:**
- Check that tmux is installed: `which tmux`
- Ensure you started Claude CLI inside tmux, not in a regular terminal

## Claude Code MCP Permissions

This repository includes `.claude/settings.local.json` with commonly used MCP permissions for developing this plugin with Claude Code. These permissions allow Claude to:

- Read and edit Neovim buffers
- Execute Vim commands
- Send tmux commands (essential for ClaudeSend functionality)
- Open, search, and save files in Neovim

**⚠️ Important Security Note**: Always use version control (git) frequently when working with AI assistants. The included permissions are suggestions - review and adjust them based on your comfort level and needs.
## Development

To contribute or modify the plugin:

1. Clone the repository
2. Make your changes
3. Test with a local Neovim setup
4. Submit a pull request

## Roadmap

- [x] Edit Neovim buffers from Claude CLI
- [x] Send and submit messages from Neovim to Claude CLI
- [ ] Automatic diff views
- [ ] Answer Claude prompts from Neovim
- [ ] Send entire buffers to Claude CLI

## The Story Behind ClaudeSend

Curious about the journey of implementing the `:ClaudeSend` command? Read [The Tale of the Delayed Enter Key](story.md) - a whimsical story about our adventures in terminal automation and the discovery of the 0.1-second solution.

## License

MIT License
