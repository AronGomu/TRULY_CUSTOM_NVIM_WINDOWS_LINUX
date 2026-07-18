-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
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
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()

      vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = 'Harpoon [A]dd file' })
      vim.keymap.set('n', '<leader>H', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Open [H]arpoon menu' })

      for i = 1, 9 do
        local slot = i
        vim.keymap.set('n', '<leader><leader>' .. slot, function() harpoon:list():replace_at(slot) end, { desc = 'Assign file to Harpoon slot ' .. slot })
      end

      for i = 1, 10 do
        local slot = i
        local key = slot == 10 and '0' or tostring(slot)
        vim.keymap.set('n', '<leader>' .. key, function() harpoon:list():select(slot) end, { desc = 'Harpoon file ' .. slot })
      end
    end,
  },

  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      -- Edit FS like buffer. :w applies renames/deletes/creates.
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ['<C-h>'] = false, -- keep window-nav maps from init.lua
        ['<C-l>'] = false,
      },
    },
    dependencies = { { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font } },
    -- oil docs: lazy-load breaks some dir-open cases
    lazy = false,
    keys = {
      { '-', function() require('oil').open() end, desc = 'Open parent dir (oil)' },
      { '<leader>o', function() require('oil').open() end, desc = '[O]il file explorer' },
    },
  },

  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      open_mapping = [[<leader>\]],
      direction = 'horizontal',
      size = function() return math.floor(vim.o.lines / 2) end,
      insert_mappings = false,
      terminal_mappings = true,
    },
  },
}
