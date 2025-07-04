if vim.g.loaded_claude_cli then
  return
end
vim.g.loaded_claude_cli = 1

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    require("claude-cli.client").disconnect()
    require("claude-cli.server").stop()
  end,
})