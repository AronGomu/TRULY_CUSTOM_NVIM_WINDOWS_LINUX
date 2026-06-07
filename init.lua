vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false
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

-- Sync clipboard between OS and Neovim.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- [[ Basic Keymaps ]]
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

          local cwd = vim.uv.cwd()
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
        vim.bo[preview_buf].filetype = vim.filetype.match { filename = path } or ''

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

        pcall(vim.treesitter.start, preview_buf)
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
        },
        filesystem = {
          follow_current_file = { enabled = false },
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
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', function()
        builtin.live_grep {
          path_display = function(_, path) return smart_truncate_path(_, path, true) end,

          layout_strategy = 'horizontal',
          layout_config = {
            width = 0.9,
            horizontal = {
              preview_width = 0.65,
            },
          },
        }
      end, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader><leader>', project_recent_files, { desc = '[ ] Search Recent Project Files' })
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
      ---@type table<string, vim.lsp.Config>
      local servers = {
        stylua = {}, -- Used to format Lua code

        -- Special Lua Config, as recommended by neovim help docs
        lua_ls = {
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
        -- You can add other tools here that you want Mason to install
      })

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
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
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
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
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
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
          MiniStatuslineDevinfo = { fg = '$fg', bg = '$bg1' }, -- mini.statusline git/diagnostic/LSP section.
          MiniStatuslineFilename = { fg = '$fg', bg = '$bg1' }, -- mini.statusline filename section.
          MiniStatuslineFileinfo = { fg = '$fg', bg = '$bg1' }, -- mini.statusline filetype/encoding section.
          MiniStatuslineInactive = { fg = '$grey', bg = '$bg1' }, -- mini.statusline when the window is inactive.
        },
      }
      vim.cmd.colorscheme 'onedark'
    end,
  },

  -- { 'folke/tokyonight.nvim',
  --   priority = 1000,
  --   config = function()
  --     ---@diagnostic disable-next-line: missing-fields
  --     require('tokyonight').setup {
  --       styles = {
  --         comments = { italic = false }, -- Disable italics in comments
  --       },
  --     }
  --
  --     vim.cmd.colorscheme 'tokyonight-night'
  --   end,
  -- },

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

      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field

      statusline.section_location = function() return '%2l:%-2v' end
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_git = function() return '' end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_filename = function()
        local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':~:.')

        if fname == '' then return '[No File Selected]' end

        local win_width = vim.api.nvim_win_get_width(0)

        local max_len = math.floor(win_width * 0.6)

        if #fname <= max_len then return fname end

        return '...' .. fname:sub(#fname - max_len + 4)
      end

      -- ... and there is more!
      --  Check out: https://github.com/nvim-mini/mini.nvim
    end,
  },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'main',
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter-intro`
    config = function()
      -- ensure basic parser are installed
      local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
      require('nvim-treesitter').install(parsers)

      ---@param buf integer
      ---@param language string
      local function treesitter_try_attach(buf, language)
        -- check if parser exists and load it
        if not vim.treesitter.language.add(language) then return end
        -- enables syntax highlighting and other treesitter features
        vim.treesitter.start(buf, language)

        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end

      local available_parsers = require('nvim-treesitter').get_available()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local buf, filetype = args.buf, args.match

          local language = vim.treesitter.language.get_lang(filetype)
          if not language then return end

          local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

          if vim.tbl_contains(installed_parsers, language) then
            -- enable the parser if it is installed
            treesitter_try_attach(buf, language)
          elseif vim.tbl_contains(available_parsers, language) then
            -- if a parser is available in `nvim-treesitter` auto install it, and enable it after the installation is done
            require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
          else
            -- try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
            treesitter_try_attach(buf, language)
          end
        end,
      })
    end,
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
    opts = {},
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
