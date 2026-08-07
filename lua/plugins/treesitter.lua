---@module 'lazy'
---@type LazySpec
return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'master', -- Neovim 0.10/0.11 compatibility branch
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter-intro`
    opts = {
      parser_install_dir = vim.fn.stdpath 'data' .. '/site',
      ensure_installed = {
        'angular',
        'bash',
        'c',
        'c_sharp',
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
        'razor',
        'scss',
        'typescript',
        'vim',
        'vimdoc',
        'xml',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts) require('nvim-treesitter.configs').setup(opts) end,
  },
}
