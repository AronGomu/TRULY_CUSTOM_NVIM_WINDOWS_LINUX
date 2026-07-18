local launch_dir = vim.fn.getcwd()
local first_arg = vim.fn.argv(0)
if first_arg ~= nil and first_arg ~= '' and vim.fn.isdirectory(first_arg) == 1 then
  launch_dir = vim.fn.fnamemodify(first_arg, ':p')
  vim.cmd.cd(vim.fn.fnameescape(launch_dir))
end

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.opt.shortmess:append 'I'
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.cursorcolumn = true
vim.opt.colorcolumn = '80,120'
vim.o.scrolloff = 10
vim.o.confirm = true
vim.opt.shada = "'20,<50,s10,h"
vim.opt_local.conceallevel = 2

-- Show absolute file paths; shorten the home directory prefix to ~/.
local function shorten_topbar_path(path)
  -- Account for the spaces surrounding the path in 'tabline'.
  local available_width = math.max(vim.o.columns - 2, 1)
  if vim.fn.strdisplaywidth(path) <= available_width then return path end

  local separator = package.config:sub(1, 1)
  local prefix = path:sub(1, 1) == separator and separator or ''
  local path_without_prefix = prefix == '' and path or path:sub(2)
  local parts = vim.split(path_without_prefix, separator, { plain = true })
  local shortened = path

  -- Shorten folders from left to right until the path fits. Keep the filename intact.
  for index = 1, #parts - 1 do
    local abbreviation = vim.fn.strcharpart(parts[index], 0, 3) .. '...'
    if vim.fn.strdisplaywidth(abbreviation) < vim.fn.strdisplaywidth(parts[index]) then parts[index] = abbreviation end

    shortened = prefix .. table.concat(parts, separator)
    if vim.fn.strdisplaywidth(shortened) <= available_width then return shortened end
  end

  return shortened
end

local theme_state_path = vim.fn.stdpath('state') .. '/selected-theme'

local function read_persisted_theme()
  local readable, lines = pcall(vim.fn.readfile, theme_state_path)
  if readable and lines[1] ~= nil and lines[1] ~= '' then return lines[1] end
end

local persisted_theme = read_persisted_theme()

local function persist_theme(theme)
  if theme == nil or theme == '' then return end

  vim.fn.mkdir(vim.fn.fnamemodify(theme_state_path, ':h'), 'p')
  local written, result = pcall(vim.fn.writefile, { theme }, theme_state_path)
  if not written or result == -1 then
    vim.notify('Could not save theme selection', vim.log.levels.WARN, { title = 'Themes' })
    return
  end
  persisted_theme = theme
end

local theme_picker = { active = false, selected = nil }

_G.nvim_topbar_path = function()
  if theme_picker.active then return 'Theme: ' .. (theme_picker.selected or vim.g.colors_name or 'default') end

  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= '' then return '' end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return '[No File Selected]' end

  path = vim.uv.fs_realpath(path) or vim.fs.normalize(path)
  path = vim.fn.fnamemodify(path, ':~')

  return shorten_topbar_path(path)
end

vim.o.showtabline = 2
vim.o.tabline = '%#TabLineFill# %{v:lua.nvim_topbar_path()} '

local function highlight_color(groups, attribute, fallback)
  for _, group in ipairs(groups) do
    local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attribute]
    if value ~= nil then return value end
  end
  return fallback
end

local function preserve_transparent_theme()
  local dark_theme = vim.o.background == 'dark'
  local fallback_bg = dark_theme and 0x282c34 or 0xf0f0f0
  local fallback_fg = dark_theme and 0xabb2bf or 0x383a42
  local normal_bg = highlight_color({ 'Normal' }, 'bg', highlight_color({ 'MiniStatuslineModeNormal' }, 'fg', fallback_bg))
  local normal_fg = highlight_color({ 'Normal' }, 'fg', fallback_fg)
  local muted_fg = highlight_color({ 'Comment', 'LineNr' }, 'fg', normal_fg)
  local filename_bg = highlight_color({ 'StatusLine', 'StatusLineNC', 'Pmenu' }, 'bg', normal_bg)
  local info_bg = highlight_color({ 'MiniStatuslineDevinfo', 'Pmenu', 'NormalFloat' }, 'bg', filename_bg)

  if info_bg == filename_bg then info_bg = highlight_color({ 'CursorLine', 'Visual' }, 'bg', filename_bg) end

  local accents = {
    Normal = highlight_color({ 'MiniStatuslineModeNormal' }, 'bg', highlight_color({ 'String', 'DiagnosticOk' }, 'fg', 0x98c379)),
    Insert = highlight_color({ 'MiniStatuslineModeInsert' }, 'bg', highlight_color({ 'Function', 'DiagnosticInfo' }, 'fg', 0x61afef)),
    Visual = highlight_color({ 'MiniStatuslineModeVisual' }, 'bg', highlight_color({ 'Keyword', 'Statement' }, 'fg', 0xc678dd)),
    Replace = highlight_color({ 'MiniStatuslineModeReplace' }, 'bg', highlight_color({ 'DiagnosticError', 'ErrorMsg' }, 'fg', 0xe06c75)),
    Command = highlight_color({ 'MiniStatuslineModeCommand' }, 'bg', highlight_color({ 'DiagnosticWarn', 'WarningMsg' }, 'fg', 0xd19a66)),
    Other = highlight_color({ 'MiniStatuslineModeOther' }, 'bg', highlight_color({ 'DiagnosticHint', 'Special' }, 'fg', 0x56b6c2)),
  }
  local git_accent = highlight_color({ 'MiniStatuslineGit' }, 'bg', highlight_color({ 'DiagnosticWarn', 'Character' }, 'fg', 0xe5c07b))

  for _, group in ipairs {
    'Normal',
    'NormalNC',
    'EndOfBuffer',
    'SignColumn',
    'FoldColumn',
    'CursorLine',
    'CursorColumn',
    'ColorColumn',
    'LineNr',
    'CursorLineNr',
  } do
    local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
    if next(highlight) ~= nil then
      highlight.bg = nil
      vim.api.nvim_set_hl(0, group, highlight)
    end
  end

  vim.api.nvim_set_hl(0, 'StatusLine', { fg = normal_fg, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = muted_fg, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGit', { fg = normal_bg, bg = git_accent, bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGitSep', { fg = git_accent, bg = info_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGitSepFilename', { fg = git_accent, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineInfoSep', { fg = info_bg, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { fg = normal_fg, bg = info_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = normal_fg, bg = filename_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo', { fg = normal_fg, bg = info_bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineInactive', { fg = muted_fg, bg = filename_bg })

  for mode, accent in pairs(accents) do
    local group = 'MiniStatuslineMode' .. mode
    vim.api.nvim_set_hl(0, group, { fg = normal_bg, bg = accent, bold = true })
    vim.api.nvim_set_hl(0, group .. 'GitSep', { fg = accent, bg = git_accent })
    vim.api.nvim_set_hl(0, group .. 'Sep', { fg = accent, bg = info_bg })
    vim.api.nvim_set_hl(0, group .. 'SepFilename', { fg = accent, bg = filename_bg })
  end
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('PreserveTransparentTheme', { clear = true }),
  desc = 'Keep editor transparency and Powerline colors when switching themes',
  callback = function(args)
    if theme_picker.active then
      theme_picker.selected = args.match
      vim.cmd.redrawtabline()
    end
    vim.schedule(preserve_transparent_theme)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('ThemePickerTopbar', { clear = true }),
  pattern = 'TelescopePrompt',
  desc = 'Restore the filepath in the top bar after closing the theme picker',
  callback = function(args)
    if not theme_picker.active then return end

    vim.api.nvim_create_autocmd('BufWipeout', {
      buffer = args.buf,
      once = true,
      callback = function()
        theme_picker.active = false
        theme_picker.selected = nil
        vim.schedule(function()
          persist_theme(vim.g.colors_name)
          vim.cmd.redrawtabline()
        end)
      end,
    })
  end,
})

if persisted_theme ~= nil then
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('PersistedTheme', { clear = true }),
    once = true,
    desc = 'Restore the selected colorscheme after plugins load',
    callback = function()
      vim.schedule(function()
        local applied = pcall(vim.cmd.colorscheme, persisted_theme)
        if not applied then
          vim.notify('Saved theme is no longer available: ' .. persisted_theme, vim.log.levels.WARN, { title = 'Themes' })
        end
      end)
    end,
  })
end

-- Angular project templates: use htmlangular so Angular LSP + treesitter apply.
vim.filetype.add {
  extension = {
    html = function(path)
      if vim.fs.root(path, { 'angular.json', 'nx.json' }) then return 'htmlangular' end
      return 'html'
    end,
  },
}

-- Sync clipboard between OS and Neovim.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- [[ Basic Keymaps ]]
vim.api.nvim_create_user_command('Q', 'quitall', { desc = 'Quit Neovim' })

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = { float = true },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  { 'NMAC427/guess-indent.nvim', opts = {} },

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    ---@module 'gitsigns'
    ---@type Gitsigns.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      signs = {
        add = { text = '+' }, ---@diagnostic disable-line: missing-fields
        change = { text = '~' }, ---@diagnostic disable-line: missing-fields
        delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
        topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
        changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
      },
    },
  },

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter',
    ---@module 'which-key'
    ---@type wk.Opts
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },

  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    keys = {
      {
        '<leader>t',
        function()
          local manager = require 'neo-tree.sources.manager'
          local state = manager.get_state 'filesystem'

          if state and state.winid and vim.api.nvim_win_is_valid(state.winid) then
            vim.cmd 'Neotree close'
            return
          end

          -- Clean up stale hidden Neo-tree buffers. They can be left behind when
          -- starting Neovim with a directory argument like `nvim .`, and Neo-tree
          -- may otherwise fail with E95 when naming its new tree buffer.
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr):match('neo%-tree filesystem %[%d+%]$') then
              pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
            end
          end

          local cwd = launch_dir or vim.uv.cwd()
          local project_root = vim.fn.systemlist({ 'git', '-C', cwd, 'rev-parse', '--show-toplevel' })[1]
          if vim.v.shell_error ~= 0 or project_root == nil or project_root == '' then project_root = cwd end

          local sep = package.config:sub(1, 1)
          local current_file = vim.api.nvim_buf_get_name(0)
          local current_real = current_file ~= '' and vim.uv.fs_realpath(current_file) or nil
          local root_real = vim.uv.fs_realpath(project_root) or project_root
          local current_is_in_project = current_real
            and vim.fn.filereadable(current_real) == 1
            and (current_real == root_real or current_real:sub(1, #root_real + 1) == root_real .. sep)

          if current_is_in_project then
            vim.cmd(
              'Neotree filesystem dir='
                .. vim.fn.fnameescape(project_root)
                .. ' reveal_file='
                .. vim.fn.fnameescape(current_real)
            )
          else
            vim.cmd('Neotree filesystem show dir=' .. vim.fn.fnameescape(project_root))
            vim.schedule(function()
              state = manager.get_state 'filesystem'
              if state and state.tree then pcall(require('neo-tree.sources.common.commands').close_all_nodes, state) end
            end)
          end
        end,
        desc = 'Toggle file tree',
      },
    },
    config = function()
      local preview_group = vim.api.nvim_create_augroup('neo-tree-auto-preview', { clear = true })
      local preview_win
      local preview_buf
      local preview_path

      local function close_preview()
        if preview_win and vim.api.nvim_win_is_valid(preview_win) then vim.api.nvim_win_close(preview_win, true) end
        if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then vim.api.nvim_buf_delete(preview_buf, { force = true }) end
        preview_win = nil
        preview_buf = nil
        preview_path = nil
      end

      local function show_preview(state, path)
        if preview_path == path and preview_win and vim.api.nvim_win_is_valid(preview_win) then return end
        close_preview()

        local ok, lines = pcall(vim.fn.readfile, path, '', 500)
        if not ok then return end

        preview_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
        vim.bo[preview_buf].bufhidden = 'wipe'
        vim.bo[preview_buf].buftype = 'nofile'
        vim.bo[preview_buf].modifiable = false
        local filetype = vim.filetype.match { filename = path } or ''
        vim.bo[preview_buf].filetype = filetype
        vim.bo[preview_buf].syntax = filetype

        local function start_treesitter()
          local language = vim.treesitter.language.get_lang(filetype)
          if not language or not vim.api.nvim_buf_is_valid(preview_buf) then return end
          pcall(vim.treesitter.start, preview_buf, language)
        end

        local tree_width = vim.api.nvim_win_get_width(state.winid)
        local width = math.min(100, vim.o.columns - tree_width - 4)
        local height = math.min(vim.o.lines - 6, math.max(10, #lines))
        if width < 10 or height < 5 then return end

        preview_win = vim.api.nvim_open_win(preview_buf, false, {
          relative = 'editor',
          row = 1,
          col = tree_width + 2,
          width = width,
          height = height,
          border = 'rounded',
          title = ' Preview ',
          title_pos = 'left',
          focusable = false,
          style = 'minimal',
        })
        vim.wo[preview_win].number = true
        preview_path = path

        vim.schedule(start_treesitter)
      end

      require('neo-tree').setup {
        popup_border_style = 'rounded',
        event_handlers = {
          {
            event = 'neo_tree_buffer_enter',
            handler = function()
              local bufnr = vim.api.nvim_get_current_buf()

              vim.api.nvim_clear_autocmds { group = preview_group, buffer = bufnr }
              vim.api.nvim_create_autocmd('CursorMoved', {
                group = preview_group,
                buffer = bufnr,
                callback = function()
                  local manager = require 'neo-tree.sources.manager'
                  local state = manager.get_state 'filesystem'
                  if
                    not state
                    or not state.tree
                    or not state.winid
                    or not vim.api.nvim_win_is_valid(state.winid)
                    or vim.api.nvim_get_current_win() ~= state.winid
                  then
                    close_preview()
                    return
                  end

                  local ok, node = pcall(state.tree.get_node, state.tree)
                  if ok and node and node.type == 'file' then
                    show_preview(state, node.path)
                  else
                    close_preview()
                  end
                end,
              })
            end,
          },
          {
            event = 'neo_tree_buffer_leave',
            handler = close_preview,
          },
          {
            event = 'file_opened',
            handler = function()
              close_preview()
              require('neo-tree.command').execute { action = 'close' }
            end,
          },
        },
        filesystem = {
          follow_current_file = { enabled = false },
          hijack_netrw_behavior = 'disabled',
        },
      }
    end,
  },

  -- NOTE: Plugins can specify dependencies.

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    enabled = true,
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },

    config = function()
      local function truncate_path(max, path)
        if #path > max then return '...' .. string.sub(path, -(max - 3)) end
        return path
      end

      local function smart_truncate_path(_, path, only_filename)
        local max = 65 -- change width here

        local sep = package.config:sub(1, 1) -- get separator on any OS by extracting the first char of the path
        local parts = vim.split(path, sep)
        local filename = parts[#parts] -- get the last element of the array
        local dir_path = ''
        for i = 1, #parts - 1 do
          dir_path = dir_path .. parts[i] .. sep
        end

        if only_filename then
          return truncate_path(max, filename)
        else
          return truncate_path(max, dir_path .. filename)
        end
      end

      require('telescope').setup {
        defaults = {
          path_display = function(_, path) return smart_truncate_path(_, path, false) end,
          layout_config = { width = 0.9 },
        },
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- Track files as you visit them, newest first, so <leader><leader> can show
      -- a project-local MRU (most recently used) list instead of Telescope's
      -- global oldfiles list.
      local recent_project_files = {}

      local function normalize_path(path) return vim.uv.fs_realpath(path) or vim.fn.fnamemodify(path, ':p') end

      local function is_inside_project(path)
        local cwd = normalize_path(vim.loop.cwd())
        path = normalize_path(path)
        return path == cwd or path:sub(1, #cwd + 1) == cwd .. package.config:sub(1, 1)
      end

      local function remember_file(path)
        if path == nil or path == '' or vim.fn.filereadable(path) ~= 1 or not is_inside_project(path) then return end

        path = normalize_path(path)

        for i = #recent_project_files, 1, -1 do
          if recent_project_files[i] == path then table.remove(recent_project_files, i) end
        end

        table.insert(recent_project_files, 1, path)
      end

      vim.api.nvim_create_autocmd('BufEnter', {
        group = vim.api.nvim_create_augroup('project-recent-files', { clear = true }),
        callback = function(args) remember_file(vim.api.nvim_buf_get_name(args.buf)) end,
      })

      local function project_recent_files()
        local seen = {}
        local results = {}
        local current_path = normalize_path(vim.api.nvim_buf_get_name(0))

        local function add(path)
          if path == nil or path == '' or vim.fn.filereadable(path) ~= 1 or not is_inside_project(path) then return end
          path = normalize_path(path)
          if path == current_path or seen[path] then return end
          seen[path] = true
          table.insert(results, path)
        end

        -- First: files visited in this Neovim session, ordered newest to oldest.
        for _, path in ipairs(recent_project_files) do
          add(path)
        end

        -- Then: persisted oldfiles from this project only, also newest to oldest.
        for _, path in ipairs(vim.v.oldfiles) do
          add(path)
        end

        require('telescope.pickers')
          .new({}, {
            prompt_title = 'Recent Project Files',
            finder = require('telescope.finders').new_table {
              results = results,
              entry_maker = function(path)
                return {
                  value = path,
                  ordinal = path,
                  display = smart_truncate_path(nil, path, true),
                  path = path,
                }
              end,
            },
            sorter = require('telescope.config').values.generic_sorter {},
            previewer = require('telescope.config').values.file_previewer {},
          })
          :find()
      end

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.api.nvim_create_user_command('Themes', function()
        local colors = vim.fn.getcompletion('', 'color')
        local longest_name = 0
        for _, color in ipairs(colors) do
          longest_name = math.max(longest_name, vim.fn.strdisplaywidth(color))
        end

        local picker_width = math.min(vim.o.columns - 2, longest_name + 6)
        local picker_height = math.min(vim.o.lines - 2, #colors + 4)
        local options = require('telescope.themes').get_dropdown {
          colors = colors,
          enable_preview = true,
          prompt_title = false,
          results_title = false,
          preview_title = false,
          prompt_prefix = '  ',
          selection_caret = '  ',
          entry_prefix = '  ',
          layout_config = {
            width = picker_width,
            height = picker_height,
            prompt_position = 'top',
            preview_cutoff = math.huge,
          },
        }

        theme_picker.active = true
        theme_picker.selected = vim.g.colors_name or 'default'
        vim.cmd.redrawtabline()

        local opened, error_message = pcall(builtin.colorscheme, options)
        if not opened then
          theme_picker.active = false
          theme_picker.selected = nil
          vim.cmd.redrawtabline()
          error(error_message)
        end
      end, { desc = 'Preview and select an installed colorscheme', force = true })
      -- User commands must start uppercase, so expose the requested lowercase spelling as an exact command-line alias.
      vim.cmd [[cnoreabbrev <expr> themes getcmdtype() ==# ':' && getcmdline() ==# 'themes' ? 'Themes' : 'themes']]

      local search_layout = {
        layout_strategy = 'vertical',
        layout_config = {
          width = 0.9,
          height = 0.9,
          prompt_position = 'bottom',
          preview_cutoff = 1,
          -- Leave five result rows below the preview (plus the prompt and borders).
          preview_height = function(_, _, height) return math.max(1, height - 12) end,
        },
      }

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', function() builtin.find_files(search_layout) end, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', function()
        builtin.live_grep(vim.tbl_deep_extend('force', search_layout, {
          path_display = function(_, path) return smart_truncate_path(_, path, true) end,
        }))
      end, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>fr', project_recent_files, { desc = '[F]iles [R]ecent Project' })
      vim.keymap.set('n', '<leader>sz', function()
        builtin.oldfiles { path_display = function(_, path) return smart_truncate_path(_, path, true) end }
      end, { desc = '[S]earch Recent Files from all projects' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader>s.', builtin.buffers, { desc = ' [S]earch existing buffers (.)' })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })

      -- Override default behavior and theme when searching
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set(
        'n',
        '<leader>s/',
        function()
          builtin.live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end,
        { desc = '[S]earch [/] in Open Files' }
      )
    end,
  },

  -- LSP Plugins
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      {
        'mason-org/mason.nvim',
        ---@module 'mason.settings'
        ---@type MasonSettings
        ---@diagnostic disable-next-line: missing-fields
        opts = {},
      },
      -- Maps LSP server names between nvim-lspconfig and Mason package names.
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      vim.api.nvim_create_autocmd('WinEnter', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-float-focus', { clear = true }),
        callback = function(event)
          if not vim.b[event.buf].lsp_floating_preview then return end
          vim.keymap.set('n', '<Esc><Esc>', '<C-w>p', {
            buffer = event.buf,
            desc = 'Return focus from LSP documentation',
          })
        end,
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      --  See `:help lsp-config` for information about keys and how to configure
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, 'blink.cmp')
      if ok_blink then capabilities = blink.get_lsp_capabilities(capabilities) end
      -- vscode-html-language-server only completes when snippet support is advertised
      capabilities.textDocument = capabilities.textDocument or {}
      capabilities.textDocument.completion = capabilities.textDocument.completion or {}
      capabilities.textDocument.completion.completionItem = capabilities.textDocument.completion.completionItem or {}
      capabilities.textDocument.completion.completionItem.snippetSupport = true

      ---@type table<string, vim.lsp.Config>
      local servers = {
        -- Formatters installed via Mason (not LSPs; enable is harmless if no config exists)
        stylua = {},
        prettierd = {},

        -- Angular Language Service: TS + HTML templates (html / htmlangular)
        -- Attaches only when angular.json or nx.json is found upward from the file.
        angularls = {
          capabilities = capabilities,
          filetypes = { 'typescript', 'html', 'typescriptreact', 'htmlangular' },
        },

        -- General HTML; Angular templates are handled exclusively by angularls.
        html = {
          capabilities = capabilities,
          filetypes = { 'html', 'templ' },
          init_options = {
            provideFormatter = false, -- prefer prettierd via conform
            embeddedLanguages = { css = true, javascript = true },
            configurationSection = { 'html', 'css', 'javascript' },
          },
        },

        -- Component / global stylesheets
        cssls = {
          capabilities = capabilities,
        },

        -- Special Lua Config, as recommended by neovim help docs
        lua_ls = {
          capabilities = capabilities,
          on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = {
                version = 'LuaJIT',
                path = { 'lua/?.lua', 'lua/?/init.lua' },
              },
              workspace = {
                checkThirdParty = false,
                -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
                --  See https://github.com/neovim/nvim-lspconfig/issues/3189
                library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
                  '${3rd}/luv/library',
                  '${3rd}/busted/library',
                }),
              },
            })
          end,
          settings = {
            Lua = {},
          },
        },
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        -- Mason package names (mapped via mason-lspconfig when names differ)
        'angular-language-server',
        'html-lsp',
        'css-lsp',
        'typescript-language-server', -- used by typescript-tools.nvim
      })

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, server in pairs(servers) do
        -- Skip pure tools that are not LSP servers
        if name ~= 'stylua' and name ~= 'prettierd' then
          vim.lsp.config(name, server)
          vim.lsp.enable(name)
        end
      end
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format { async = true, lsp_format = 'fallback' } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        htmlangular = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        scss = { 'prettierd', 'prettier', stop_after_first = true },
        less = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        jsonc = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
      },
    },
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        preset = 'default',

        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        menu = {
          draw = {
            columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
          },
        },
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets' },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  {
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('onedark').setup {
        transparent = true, -- Tell onedark not to paint the main editor background.
        styles = {
          comments = { italic = false }, -- Keep comments non-italic.
        },
        highlights = {
          -- Keep the editor transparent; only the statusline gets a background.
          Normal = { bg = 'none' }, -- Main editing area background.
          NormalNC = { bg = 'none' }, -- Main editing area in non-current windows.
          EndOfBuffer = { bg = 'none' }, -- Empty lines after the end of a file.
          SignColumn = { bg = 'none' }, -- Left column used for git signs, diagnostics, breakpoints, etc.
          FoldColumn = { bg = 'none' }, -- Left column used for code-folding markers.
          CursorLine = { bg = 'none' }, -- Highlight for the entire line under the cursor.
          CursorColumn = { bg = 'none' }, -- Highlight for the entire column under the cursor.
          ColorColumn = { bg = 'none' }, -- Vertical guide columns, like your 80 and 120 character rulers.
          LineNr = { bg = 'none' }, -- Line number column background.
          CursorLineNr = { bg = 'none' }, -- Current line number background.

          StatusLine = { fg = '$fg', bg = '$bg1' }, -- Active window statusline background.
          StatusLineNC = { fg = '$grey', bg = '$bg1' }, -- Inactive window statusline background.
          MiniStatuslineModeNormal = { fg = '$bg0', bg = '$green', fmt = 'bold' },
          MiniStatuslineModeInsert = { fg = '$bg0', bg = '$blue', fmt = 'bold' },
          MiniStatuslineModeVisual = { fg = '$bg0', bg = '$purple', fmt = 'bold' },
          MiniStatuslineModeReplace = { fg = '$bg0', bg = '$red', fmt = 'bold' },
          MiniStatuslineModeCommand = { fg = '$bg0', bg = '$orange', fmt = 'bold' },
          MiniStatuslineModeOther = { fg = '$bg0', bg = '$cyan', fmt = 'bold' },
          MiniStatuslineGit = { fg = '$bg0', bg = '$yellow', fmt = 'bold' },
          MiniStatuslineModeNormalGitSep = { fg = '$green', bg = '$yellow' },
          MiniStatuslineModeInsertGitSep = { fg = '$blue', bg = '$yellow' },
          MiniStatuslineModeVisualGitSep = { fg = '$purple', bg = '$yellow' },
          MiniStatuslineModeReplaceGitSep = { fg = '$red', bg = '$yellow' },
          MiniStatuslineModeCommandGitSep = { fg = '$orange', bg = '$yellow' },
          MiniStatuslineModeOtherGitSep = { fg = '$cyan', bg = '$yellow' },
          MiniStatuslineGitSep = { fg = '$yellow', bg = '$bg2' },
          MiniStatuslineGitSepFilename = { fg = '$yellow', bg = '$bg1' },
          MiniStatuslineModeNormalSep = { fg = '$green', bg = '$bg2' },
          MiniStatuslineModeInsertSep = { fg = '$blue', bg = '$bg2' },
          MiniStatuslineModeVisualSep = { fg = '$purple', bg = '$bg2' },
          MiniStatuslineModeReplaceSep = { fg = '$red', bg = '$bg2' },
          MiniStatuslineModeCommandSep = { fg = '$orange', bg = '$bg2' },
          MiniStatuslineModeOtherSep = { fg = '$cyan', bg = '$bg2' },
          MiniStatuslineModeNormalSepFilename = { fg = '$green', bg = '$bg1' },
          MiniStatuslineModeInsertSepFilename = { fg = '$blue', bg = '$bg1' },
          MiniStatuslineModeVisualSepFilename = { fg = '$purple', bg = '$bg1' },
          MiniStatuslineModeReplaceSepFilename = { fg = '$red', bg = '$bg1' },
          MiniStatuslineModeCommandSepFilename = { fg = '$orange', bg = '$bg1' },
          MiniStatuslineModeOtherSepFilename = { fg = '$cyan', bg = '$bg1' },
          MiniStatuslineInfoSep = { fg = '$bg2', bg = '$bg1' },
          MiniStatuslineDevinfo = { fg = '$fg', bg = '$bg2' }, -- mini.statusline git/diagnostic/LSP section.
          MiniStatuslineFilename = { fg = '$fg', bg = '$bg1' }, -- mini.statusline filename section.
          MiniStatuslineFileinfo = { fg = '$fg', bg = '$bg2' }, -- mini.statusline filetype/encoding section.
          MiniStatuslineInactive = { fg = '$grey', bg = '$bg1' }, -- mini.statusline when the window is inactive.
        },
      }
      vim.cmd.colorscheme 'onedark'
    end,
  },

  -- Dotfyle top colorschemes. Eager loading exposes every scheme to :Themes.
  { 'catppuccin/nvim', name = 'catppuccin', lazy = false },
  { 'folke/tokyonight.nvim', lazy = false },
  { 'rebelot/kanagawa.nvim', lazy = false },
  { 'rose-pine/neovim', name = 'rose-pine', lazy = false },
  { 'EdenEast/nightfox.nvim', lazy = false },
  { 'sainnhe/gruvbox-material', lazy = false },
  { 'projekt0n/github-nvim-theme', lazy = false },
  { 'sainnhe/everforest', lazy = false },
  { 'scottmckendry/cyberdream.nvim', lazy = false },
  { 'Mofiqul/vscode.nvim', lazy = false },
  { 'olimorris/onedarkpro.nvim', lazy = false },
  { 'Mofiqul/dracula.nvim', lazy = false },
  { 'shaunsingh/nord.nvim', lazy = false },
  { 'nyoom-engineering/oxocarbon.nvim', lazy = false },
  { 'marko-cerovac/material.nvim', lazy = false },
  { 'craftzdog/solarized-osaka.nvim', lazy = false },
  { 'sainnhe/sonokai', lazy = false },
  { 'AlexvZyl/nordic.nvim', lazy = false },
  { 'bluz71/vim-moonfly-colors', lazy = false },
  { 'neanias/everforest-nvim', lazy = false },
  { 'tiagovla/tokyodark.nvim', lazy = false },
  { 'ribru17/bamboo.nvim', lazy = false },
  { 'savq/melange-nvim', lazy = false },
  { 'sainnhe/edge', lazy = false },

  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@module 'todo-comments'
    ---@type TodoOptions
    ---@diagnostic disable-next-line: missing-fields
    opts = { signs = false },
  },

  { -- Collection of various small independent plugins/modules
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }

      require('mini.surround').setup()

      local statusline = require 'mini.statusline'

      local separator = vim.g.have_nerd_font and '' or '>'
      local separator_reverse = vim.g.have_nerd_font and '' or '<'

      local function group(hl, content) return '%#' .. hl .. '#' .. content end

      local function join_sections(sections)
        local visible = {}
        for _, section in ipairs(sections) do
          if section ~= '' then table.insert(visible, section) end
        end
        return table.concat(visible, ' ')
      end

      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          active = function()
            local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
            local git = statusline.section_git { trunc_width = 40 }
            local devinfo = join_sections {
              statusline.section_diff { trunc_width = 75 },
              statusline.section_diagnostics { trunc_width = 75 },
              statusline.section_lsp { trunc_width = 75 },
            }
            local filename = statusline.section_filename { trunc_width = 140 }
            local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
            local search = statusline.section_searchcount { trunc_width = 75 }
            local location = statusline.section_location { trunc_width = 75 }

            local left = group(mode_hl, ' ' .. mode .. ' ')
            if git ~= '' then
              left = left
                .. group(mode_hl .. 'GitSep', separator)
                .. group('MiniStatuslineGit', ' ' .. git .. ' ')

              if devinfo == '' then
                left = left .. group('MiniStatuslineGitSepFilename', separator)
              else
                left = left
                  .. group('MiniStatuslineGitSep', separator)
                  .. group('MiniStatuslineDevinfo', ' ' .. devinfo .. ' ')
                  .. group('MiniStatuslineInfoSep', separator)
              end
            elseif devinfo == '' then
              left = left .. group(mode_hl .. 'SepFilename', separator)
            else
              left = left
                .. group(mode_hl .. 'Sep', separator)
                .. group('MiniStatuslineDevinfo', ' ' .. devinfo .. ' ')
                .. group('MiniStatuslineInfoSep', separator)
            end
            left = left .. '%<' .. group('MiniStatuslineFilename', ' ' .. filename .. ' ')

            local right
            if fileinfo == '' then
              right = group(mode_hl .. 'SepFilename', separator_reverse)
            else
              right = group('MiniStatuslineInfoSep', separator_reverse)
                .. group('MiniStatuslineFileinfo', ' ' .. fileinfo .. ' ')
                .. group(mode_hl .. 'Sep', separator_reverse)
            end
            right = right .. group(mode_hl, ' ' .. join_sections { search, location } .. ' ')

            return left .. '%=' .. right
          end,
        },
      }
      ---@diagnostic disable-next-line: duplicate-set-field

      statusline.section_location = function() return '%2l:%-2v' end
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_git = function(args)
        if statusline.is_truncated(args.trunc_width) then return '' end

        local branch = vim.b.gitsigns_head
        if branch == nil or branch == '' then return '' end

        local icon = vim.g.have_nerd_font and '' or 'git:'
        return icon .. ' ' .. branch
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_filename = function()
        local path = vim.api.nvim_buf_get_name(0)

        if path == '' then return '[No File Selected]' end

        local fname = vim.fn.fnamemodify(path, ':t')

        local win_width = vim.api.nvim_win_get_width(0)

        local max_len = math.floor(win_width * 0.6)

        if vim.fn.strdisplaywidth(fname) <= max_len then return fname end

        local visible_chars = math.max(max_len - 3, 1)
        local start = math.max(vim.fn.strchars(fname) - visible_chars, 0)
        return '...' .. vim.fn.strcharpart(fname, start)
      end

      -- ... and there is more!
      --  Check out: https://github.com/nvim-mini/mini.nvim
    end,
  },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'master', -- Neovim 0.10/0.11 compatibility branch
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter-intro`
    opts = {
      parser_install_dir = vim.fn.stdpath('data') .. '/site',
      ensure_installed = {
        'angular',
        'bash',
        'c',
        'css',
        'diff',
        'html',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'scss',
        'typescript',
        'vim',
        'vimdoc',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts) require('nvim-treesitter.configs').setup(opts) end,
  },

  {
    'rmagatti/auto-session',
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {},
  },

  {
    'kelly-lin/ranger.nvim',
    config = function()
      require('ranger-nvim').setup { replace_netrw = false }
      vim.api.nvim_set_keymap('n', '<leader>r', '', {
        noremap = true,
        callback = function() require('ranger-nvim').open(true) end,
      })
    end,
  },

  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      on_attach = function(client, bufnr)
        -- In Angular projects, prefer angularls for rename (template-aware).
        local root = vim.fs.root(bufnr, { 'angular.json', 'nx.json' })
        if root then client.server_capabilities.renameProvider = false end
      end,
      settings = {
        -- Keep tsserver focused; Angular templates are handled by angularls.
        tsserver_file_preferences = {
          includeInlayParameterNameHints = 'all',
          includeCompletionsForModuleExports = true,
        },
      },
    },
  },

  {
    'sphamba/smear-cursor.nvim',
    opts = {},
  },

  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'VeryLazy',
    priority = 1000,
    config = function()
      require('tiny-inline-diagnostic').setup()
      vim.diagnostic.config { virtual_text = false } -- Disable Neovim's default virtual text diagnostics
    end,
  },

  {
    'obsidian-nvim/obsidian.nvim',
    version = '*', -- use latest release, remove to use latest commit
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false, -- this will be removed in 4.0.0
      workspaces = {
        {
          name = 'brain',
          path = '~/brain',
        },
      },
      templates = {
        subdir = '10-Templates', -- <‑‑ the folder you just created
        date_format = '%Y-%m-%d', -- optional, used for {{date}} in the templates
        -- optional: you can give the template files a friendly name
        --   (the name that will appear in the picker)
        template_names = {
          ['media'] = 'Media-Synthesis-Template.md',
          ['idea'] = 'Idea-Synthesis-Template.md',
          ['article'] = 'Article-Template.md',
          ['project'] = 'Project-Template.md',
          ['game'] = 'Game-Concept-Template.md',
          ['fiction'] = 'Fiction-Template.md',
          ['biz'] = 'Business-Template.md',
        },
      },
    },
  },

  {
    'dinhhuy258/git.nvim',
    config = function() require('git').setup() end,
  },

  -- Custom user plugins (see lua/custom/plugins/)
  { import = 'custom.plugins' },
}, { ---@diagnostic disable-line: missing-fields
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
