---@module 'lazy'
---@type LazySpec
return {
  { -- GitHub Copilot backend; suggestions are shown in the blink.cmp menu via blink-copilot
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
}
