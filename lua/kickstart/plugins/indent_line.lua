---@module 'lazy'
---@type LazySpec
return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    cond = not vim.g.vscode,
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    ---@module 'ibl'
    ---@type ibl.config
    opts = {},
  },
}
