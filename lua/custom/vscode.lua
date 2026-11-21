-- Helper module to centralize VS Code (vscode-neovim) specific adjustments
local M = {}

M.is_vscode = vim.g.vscode ~= nil

-- Run a VS Code command through the vscode-neovim bridge
local function action(cmd) require('vscode').action(cmd) end

function M.setup_keymaps()
  if not M.is_vscode then return end

  vim.keymap.set('n', 'grs', function() action 'workbench.action.gotoSymbol' end, { silent = true, desc = '[G]oto [S]ymbol' })
  vim.keymap.set('n', 'grd', function() action 'editor.action.revealDefinition' end, { silent = true, desc = '[G]oto [D]efinition' })
end

function M.setup_options()
  if not M.is_vscode then return end

  -- NOTE: VS Code shows no which-key popup, so give multi-key sequences plenty of time
  vim.o.timeoutlen = 10000
end

return M
