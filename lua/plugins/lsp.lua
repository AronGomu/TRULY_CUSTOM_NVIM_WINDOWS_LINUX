---@module 'lazy'
---@type LazySpec
return {
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
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, { 'angular.json', 'nx.json' })
            if root then on_dir(root) end
          end,
          get_language_id = function(_, filetype) return filetype == 'htmlangular' and 'html' or filetype end,
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
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'VeryLazy',
    priority = 1000,
    config = function()
      require('tiny-inline-diagnostic').setup()
      vim.diagnostic.config { virtual_text = false } -- Disable Neovim's default virtual text diagnostics
    end,
  },
}
