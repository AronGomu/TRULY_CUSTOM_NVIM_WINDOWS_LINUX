local is_windows = require('utils.platform').is_windows

---@module 'lazy'
---@type LazySpec
return {
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

  {
    'MagicDuck/grug-far.nvim',
    ---@module 'grug-far'
    ---@type grug.far.OptionsOverride
    opts = {},
    cmd = { 'GrugFar', 'GrugFarWithin' },
    keys = {
      {
        '<leader>sR',
        function() require('grug-far').open() end,
        desc = '[S]earch and [R]eplace',
      },
      {
        '<leader>sR',
        function() require('grug-far').with_visual_selection() end,
        mode = 'v',
        desc = '[S]earch and [R]eplace selection',
      },
      {
        '<leader>sW',
        function() require('grug-far').open { prefills = { search = vim.fn.expand '<cword>' } } end,
        desc = '[S]earch and replace current [W]ord',
      },
    },
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
    config = function()
      if not is_windows then
        require('git').setup()
        return
      end

      require('git').setup {
        target_branch = function()
          local result = vim.system({ 'git', 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD' }, { text = true }):wait()
          if result.code == 0 then
            local branch = vim.trim(result.stdout or ''):gsub('^origin/', '')
            if branch ~= '' then return branch end
          end

          return 'master'
        end,
      }
    end,
  },
}
