-- Fix spelling and grammar via the local llm-daemon (repo llm-daemon, client `ask fix`) and
-- replace the text in place: the selection in Visual mode, otherwise the current paragraph.
-- The daemon's `fix` preset may use a cloud model, so text only leaves the machine on <M-f>.
-- Same key as the PSReadLine handler in the PowerShell profile.
local M = {}

-- Runs the client module directly instead of ask.ps1, which saves the pwsh start (~0.6 s).
local repo = vim.fs.joinpath(vim.env.USERPROFILE or vim.env.HOME or '', 'repos', 'llm-daemon')
local python = vim.fs.joinpath(repo, '.venv', 'Scripts', 'python.exe')

local function notify(msg, level) vim.notify('Textkorrektur: ' .. msg, level or vim.log.levels.INFO) end

-- Regions are 0-based { start_row, start_col, end_row, end_col } with an exclusive end column,
-- as nvim_buf_get_text/nvim_buf_set_text expect them. Columns are bytes.

local function visual_region()
  local mode = vim.fn.mode()
  local a, b = vim.fn.getpos 'v', vim.fn.getpos '.'
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  if mode == '\22' then return nil, 'Block-Markierung wird nicht unterstützt.' end
  if a[2] > b[2] or (a[2] == b[2] and a[3] > b[3]) then
    a, b = b, a
  end
  local srow, erow = a[2] - 1, b[2] - 1
  local first = vim.api.nvim_buf_get_lines(0, srow, srow + 1, true)[1]
  local last = vim.api.nvim_buf_get_lines(0, erow, erow + 1, true)[1]
  if mode == 'V' then return { srow, 0, erow, #last } end
  -- b[3] is the 1-based first byte of the last selected character (huge after `$`): clamp it, then
  -- extend it over the remaining bytes of a multibyte character such as ä.
  local ecol = math.min(b[3], #last)
  if ecol > 0 then ecol = ecol + vim.str_utf_end(last, ecol) end
  return { srow, math.min(a[3] - 1, #first), erow, ecol }
end

local function paragraph_region()
  local function blank(lnum) return vim.fn.getline(lnum):match '^%s*$' ~= nil end
  local row = vim.fn.line '.'
  if blank(row) then return nil, 'Cursor steht nicht in einem Absatz.' end
  local first, last = row, row
  while first > 1 and not blank(first - 1) do
    first = first - 1
  end
  while last < vim.fn.line '$' and not blank(last + 1) do
    last = last + 1
  end
  return { first - 1, 0, last - 1, #vim.fn.getline(last) }
end

function M.fix()
  local region, err
  if vim.fn.mode():match '^[vV\22]' then
    region, err = visual_region()
  else
    region, err = paragraph_region()
  end
  if not region then return notify(err, vim.log.levels.WARN) end
  if vim.fn.executable(python) == 0 then return notify('Client des llm-daemon nicht gefunden (' .. python .. ').', vim.log.levels.ERROR) end

  local buf = vim.api.nvim_get_current_buf()
  local text = table.concat(vim.api.nvim_buf_get_text(buf, region[1], region[2], region[3], region[4], {}), '\n')
  if not text:match '%S' then return notify('kein Text.', vim.log.levels.WARN) end
  local tick = vim.api.nvim_buf_get_changedtick(buf)

  notify 'korrigiere …'
  -- Asynchronous, so the editor stays usable; the callback runs on the main loop via schedule_wrap.
  vim.system(
    { python, '-P', '-m', 'llm_daemon.ask', 'fix' },
    { stdin = text, env = { PYTHONPATH = repo } },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local reason = ({ [3] = 'llm-daemon nicht erreichbar.', [4] = 'Antwort abgeschnitten.' })[result.code] or vim.trim(result.stderr or '')
        return notify(reason .. ' Text bleibt unverändert.', vim.log.levels.ERROR)
      end
      -- Any edit during the request may have moved the region; replacing it would hit the wrong text.
      if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= tick then
        return notify('Text wurde inzwischen geändert, Korrektur verworfen.', vim.log.levels.WARN)
      end
      -- The client writes Windows line endings.
      local fixed = result.stdout:gsub('\r\n', '\n'):gsub('%s+$', '')
      if fixed == '' then return notify('leere Antwort.', vim.log.levels.WARN) end
      if fixed == text then return notify 'nichts zu korrigieren.' end
      vim.api.nvim_buf_set_text(buf, region[1], region[2], region[3], region[4], vim.split(fixed, '\n', { plain = true }))
      notify 'Text korrigiert.'
    end)
  )
end

function M.setup() vim.keymap.set({ 'n', 'x', 'i' }, '<M-f>', M.fix, { desc = 'Text[F]ix: correct selection or paragraph (llm-daemon)' }) end

return M
