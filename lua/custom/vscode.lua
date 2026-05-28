-- Helper module to centralize VS Code specific adjustments
local M = {}

M.is_vscode = vim.g.vscode ~= nil
M.not_vscode = not M.is_vscode

function M.cond_not_vscode()
  return { cond = not M.is_vscode }
end

function M.notify(cmd, ...)
  if not M.is_vscode then return end
  if type(vim.fn.VSCodeNotify) ~= 'function' then return end
  if select('#', ...) == 0 then
    vim.fn.VSCodeNotify(cmd)
  else
    vim.fn.VSCodeNotify(cmd, ...)
  end
end

function M.setup_keymaps()
  if not M.is_vscode then return end

  -- Keymaps that call VS Code actions via the Neovim extension bridge
  vim.keymap.set('n', 'grs', function() M.notify('workbench.action.gotoSymbol') end, { silent = true })
  vim.keymap.set('n', 'grd', function() M.notify('editor.action.revealDefinition') end, { silent = true })
  -- Additional mappings from original config are left commented for reference
  -- vim.keymap.set('n', 'gra', function() M.notify('editor.action.codeAction') end, { silent = true })
  -- vim.keymap.set('n', 'grn', function() M.notify('editor.action.rename') end, { silent = true })
  -- vim.keymap.set('n', 'grr', function() M.notify('editor.action.goToReferences') end, { silent = true })
end

return M
