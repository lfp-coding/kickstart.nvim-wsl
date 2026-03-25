-- autopairs
-- https://github.com/windwp/nvim-autopairs

---@module 'lazy'
---@type LazySpec
return {
  'windwp/nvim-autopairs',
  cond = not vim.g.vscode,
  event = 'InsertEnter',
  opts = {},
}
