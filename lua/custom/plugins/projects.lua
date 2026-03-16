return {
  -- Session management: auto-save and restore on open
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {},
    keys = {
      { '<leader>qs', function() require('persistense').load() end, desc = '[Q]uit: restore [S]ession' },
      { '<leader>ql', function() require('persistense').load { last = true } end, desc = '[Q]uit: restore [L]ast session' },
      { '<leader>qd', function() require('persistense').stop() end, desc = "[Q]uit: [D]on't save session" },
    },
  },
}
