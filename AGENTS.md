# AGENTS.md — Kickstart.nvim Configuration

This is a Neovim configuration based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
The codebase is written entirely in Lua and targets **Neovim ≥ 0.11 (latest stable or nightly)**.

---

## Repository Layout

```
init.lua                   # Main entry point — read top-to-bottom
lua/
  kickstart/
    health.lua             # :checkhealth integration
    plugins/               # Optional built-in plugin configs (uncomment in init.lua to enable)
      autopairs.lua
      debug.lua
      gitsigns.lua
      indent_line.lua
      lint.lua
      neo-tree.lua
  custom/
    plugins/
      init.lua             # Your own plugins go here (returns a LazySpec table)
.stylua.toml               # StyLua formatter config
.github/workflows/
  stylua.yml               # CI: checks formatting on PRs
```

---

## Formatting / Lint Commands

This repo uses **StyLua** as the sole code-quality tool. There are no test suites.

### Check formatting (what CI does)

```sh
stylua --check .
```

### Auto-format all Lua files

```sh
stylua .
```

### Format a single file

```sh
stylua lua/kickstart/plugins/lint.lua
```

### Install StyLua

```sh
cargo install stylua
# or via Mason inside Neovim:
#   :MasonInstall stylua
```

CI is defined in `.github/workflows/stylua.yml` and runs `stylua --check .` on every pull request.

### Health check (inside Neovim)

```
:checkhealth kickstart
```

Verifies that external dependencies (`git`, `make`, `unzip`, `rg`) are available.

---

## StyLua Configuration (`.stylua.toml`)

```toml
column_width = 160
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "None"
collapse_simple_statement = "Always"
```

Key rules:
- **2-space indentation**, never tabs.
- **160-character line width** — long lines are permitted.
- **Single quotes preferred** (`'hello'`), but double quotes are used when the string contains a single quote.
- **No parentheses** on function calls that take a single string or table literal argument:
  `require 'telescope.builtin'`, `vim.cmd.colorscheme 'tokyonight-night'`
- **Collapse simple statements** onto one line when they are trivially short:
  `if not vim.treesitter.language.add(language) then return end`

---

## Code Style Guidelines

### Requires / Imports

Use the no-parens style for single-string `require` calls:

```lua
local builtin = require 'telescope.builtin'
local lint = require 'lint'
```

Use parentheses only when passing a table or concatenated string:

```lua
require('telescope').setup { ... }
require('mason-nvim-dap').setup { automatic_installation = true }
```

Do not alias modules at the top of a file unless they are used multiple times.

### Function Definitions

Prefer local named functions for callbacks and helpers; anonymous functions are
acceptable for short one-liners inside `vim.keymap.set`:

```lua
-- Named local helper
local function map(mode, l, r, opts)
  opts = opts or {}
  opts.buffer = bufnr
  vim.keymap.set(mode, l, r, opts)
end

-- Inline lambda is fine when it's short
vim.keymap.set('n', '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
```

### Naming Conventions

| Kind | Convention | Example |
|------|-----------|---------|
| Local variables | `snake_case` | `local lint_augroup` |
| Module-level locals | `snake_case` | `local lazypath` |
| Lua module files | `snake_case` | `indent_line.lua` |
| Augroup names | `kebab-case` strings | `'kickstart-lsp-attach'` |
| Plugin spec keys | as specified by lazy.nvim | `opts`, `config`, `event`, `keys` |

### Tables and Plugin Specs

- Opening brace on the same line as the call, no space before `{`.
- Trailing comma on last table entry is accepted but not required.
- Keep related keys grouped logically (dependencies → config, opts → keymap → appearance).

```lua
{ -- Short description of plugin purpose
  'author/plugin.nvim',
  event = 'VimEnter',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    key = value,
  },
},
```

### Comments

- Use `--` for single-line comments; `--[[ ... --]]` for block comments at the
  top of a file (see `init.lua` header).
- Annotate plugin type-hints with LuaLS annotations directly above the relevant
  field:
  ```lua
  ---@module 'gitsigns'
  ---@type Gitsigns.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = { ... }
  ```
- Section headers in `init.lua` use `-- [[ Section Name ]]` surrounded by blank lines.
- Inline notes use `-- NOTE:`, warnings use `-- WARN:`, hints use `-- TIP:`.

### Error Handling

- Use `pcall` for operations that may fail at startup (e.g., loading telescope extensions):
  ```lua
  pcall(require('telescope').load_extension, 'fzf')
  ```
- Use `error()` for unrecoverable setup failures:
  ```lua
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
  ```
- Guard optional paths with early returns rather than deep nesting:
  ```lua
  if not vim.treesitter.language.add(language) then return end
  ```

### Keymaps

Always supply a `desc` field:

```lua
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
```

Use square-bracket mnemonics in descriptions to indicate the key letter:
`[S]earch [H]elp` → `<leader>sh`.

### Autocommands

Always supply a named `group` with `{ clear = true }` to avoid duplicating
autocommands on re-source:

```lua
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})
```

---

## Adding Plugins

1. **Optional kickstart plugins** — uncomment the relevant `require` line near
   the bottom of `init.lua` (e.g., `require 'kickstart.plugins.lint'`).
2. **Personal plugins** — add specs to `lua/custom/plugins/init.lua` (returns a
   `LazySpec` table). You can also create additional files in that directory and
   add `{ import = 'custom.plugins' }` to the lazy setup call.
3. Each plugin file must return a value of type `LazySpec`; annotate it:
   ```lua
   ---@module 'lazy'
   ---@type LazySpec
   return { ... }
   ```

---

## External Dependencies

Required tools (checked by `:checkhealth kickstart`):

- `git`, `make`, `unzip`, C compiler (`gcc`)
- `ripgrep` (`rg`) — used by Telescope live grep
- `fd-find` — used by Telescope file finder
- `tree-sitter` CLI
- `stylua` — Lua formatter (installed via Mason or Cargo)
- Clipboard tool: `xclip` / `xsel` (Linux), `win32yank` (Windows)

---

## Modeline

Every file is expected to be compatible with the `init.lua` modeline at the
bottom:

```lua
-- vim: ts=2 sts=2 sw=2 et
```
