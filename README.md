# AronGomu Neovim config

Personal Neovim config built from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). Focus: project navigation, fast search, Angular/TypeScript tooling, transparent themes, keyboard-first workflows.

## Highlights

- `lazy.nvim` plugin mgmt with automatic bootstrap
- Top bar showing absolute file paths with `$HOME` shortened to `~/`
- Transparent `onedark` default theme
- `:Themes` Telescope picker with live preview + persisted selection
- Powerline-style `mini.statusline` with mode, Git branch, diagnostics, LSP, file info, location
- Neo-tree project explorer with automatic syntax-highlighted file preview
- Oil editable FS buffers
- Telescope file, text, command, buffer, diagnostic, LSP search
- Project-local recent-file history
- Harpoon slots for fast file switching
- Grug Far project-wide search/replace
- Toggleterm horizontal terminal
- LSP, completion, formatting for Lua + web dev
- Angular project detection via `angular.json` or `nx.json`
- Tree-sitter parser auto-install
- Session restore, Git signs, TODO highlights, cursor animation, inline diagnostics
- Obsidian workspace support for `~/brain`

## Requirements

- Neovim 0.11+
- Git
- `make` + C compiler
- `unzip`
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd](https://github.com/sharkdp/fd)
- [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/tree/master/crates/cli)
- Clipboard provider: `xclip`, `xsel`, `wl-clipboard`, `win32yank`, or OS equivalent
- Nerd Font
- Node.js + npm for TypeScript, Angular, HTML/CSS LSPs, Prettier
- Optional: `ranger` for `<leader>r`

## Install

Back up existing config first.

### Linux/macOS

```sh
git clone https://github.com/AronGomu/TRULY_CUSTOM_NVIM_WINDOWS_LINUX.git \
  "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim
```

### Windows PowerShell

```powershell
git clone https://github.com/AronGomu/TRULY_CUSTOM_NVIM_WINDOWS_LINUX.git "$env:LOCALAPPDATA\nvim"
nvim
```

First launch installs plugins, LSP servers, formatters, Tree-sitter parsers. Run `:Lazy` or `:Mason` to inspect progress.

`lazy-lock.json` stays local because repo ignores it. `nvim-treesitter` stays on its `master` compatibility branch for Neovim 0.10/0.11; its `main` branch requires Neovim 0.12+. After branch changes, refresh plugin + parsers:

```vim
:Lazy update nvim-treesitter
:TSUpdate
```

## Project behavior

Start Neovim from project root:

```sh
nvim .
```

Config uses launch dir to:

- resolve Git root
- root Neo-tree
- filter recent project files

Top bar always shows canonical absolute file paths. Paths under `$HOME` use `~/`.

Angular workspaces receive:

- `htmlangular` template filetype
- Angular Language Service for TypeScript + templates
- HTML/CSS LSP support outside Angular templates
- TypeScript Tools with Angular-aware rename handling
- Prettier/Prettierd formatting
- Angular, HTML, CSS, JavaScript, SCSS, TypeScript Tree-sitter parsers

## Keymaps

Leader key: `Space`.

### Core

| Key | Action |
|---|---|
| `<Esc>` | Clear search highlight |
| `<Esc><Esc>` | Exit terminal mode or return from focused LSP docs |
| `<C-h/j/k/l>` | Move across splits |
| `<leader>q` | Open diagnostic location list |
| `<leader>f` | Format current buffer |
| `<leader>th` | Toggle LSP inlay hints |
| `:Q` | Quit all Neovim windows |

### Files + navigation

| Key | Action |
|---|---|
| `<leader>t` | Toggle project-rooted Neo-tree |
| `-` | Open parent dir in Oil |
| `<leader>o` | Open Oil |
| `<leader>r` | Open Ranger |
| `<leader>a` | Add file to Harpoon |
| `{count}<leader>a` | Assign file to Harpoon slot |
| `<leader>1` … `<leader>0` | Select Harpoon slots 1–10 |
| `<leader>H` | Open Harpoon menu |
| `<leader>\` | Toggle horizontal terminal |

### Search

| Key | Action |
|---|---|
| `<leader>sf` | Find files |
| `<leader>sg` | Live grep |
| `<leader>sw` | Search word/visual selection |
| `<leader>sh` | Search help |
| `<leader>sk` | Search keymaps |
| `<leader>ss` | Search Telescope pickers |
| `<leader>sd` | Search diagnostics |
| `<leader>sc` | Search commands |
| `<leader>s.` | Search open buffers |
| `<leader>sr` | Resume previous search |
| `<leader><leader>` | Recent files in current project |
| `<leader>sz` | Recent files across projects |
| `<leader>/` | Fuzzy search current buffer |
| `<leader>s/` | Grep open files |

### Search + replace

| Key | Mode | Action |
|---|---|---|
| `<leader>sR` | Normal | Open Grug Far |
| `<leader>sR` | Visual | Replace visual selection |
| `<leader>sW` | Normal | Replace word under cursor |

### LSP

| Key | Action |
|---|---|
| `gd` / `grd` | Definition |
| `grr` | References |
| `gri` | Implementation |
| `grt` | Type definition |
| `grD` | Declaration |
| `grn` | Rename |
| `gra` | Code action |
| `gO` | Document symbols |
| `gW` | Workspace symbols |
| `K` / `KK` | Show / focus hover docs |

Use `which-key` for discoverable key groups.

## Themes

Default: transparent `onedark`.

Open theme picker:

```vim
:Themes
```

Lowercase alias also works:

```vim
:themes
```

Selection persists under Neovim state dir as `selected-theme`. Theme changes preserve editor transparency + statusline colors.

Included theme families: Catppuccin, Tokyo Night, Kanagawa, Rose Pine, Nightfox, Gruvbox Material, GitHub, Everforest, Cyberdream, VS Code, Onedark Pro, Dracula, Nord, Oxocarbon, Material, Solarized Osaka, Sonokai, Nordic, Moonfly, Tokyodark, Bamboo, Melange, Edge.

## Tooling

### LSP

Mason installs/configures:

- `lua_ls`
- `angularls`
- `html`
- `cssls`
- TypeScript Language Server for `typescript-tools.nvim`

Completion uses `blink.cmp` with LSP, path, LuaSnip sources, signature help. Suggestions show auto-import modules; docs open automatically.

### Formatting

`conform.nvim` formats on save. Manual format: `<leader>f`.

- Lua: Stylua
- JS/JSX/TS/TSX/HTML/Angular/CSS/SCSS/Less/JSON/YAML/Markdown: Prettierd, fallback Prettier
- C/C++: no format-on-save fallback

### Tree-sitter

Configured parsers:

`angular`, `bash`, `c`, `css`, `diff`, `html`, `javascript`, `json`, `lua`, `luadoc`, `markdown`, `markdown_inline`, `query`, `scss`, `typescript`, `vim`, `vimdoc`.

Missing supported parsers install when matching files open.

## Structure

```text
.
├── init.lua                       # options, UI, keymaps, plugin specs, tooling
├── lua/custom/plugins/init.lua    # Grug Far, Harpoon, Oil, Toggleterm
├── lua/kickstart/plugins/         # optional Kickstart plugin examples
└── .stylua.toml                   # Lua formatting rules
```

## Maintenance

```vim
:Lazy          " plugins
:Mason         " LSPs/tools
:ConformInfo   " formatter status
:checkhealth   " Neovim health
```

Update plugins:

```vim
:Lazy update
```

Format Lua config with Stylua:

```sh
stylua init.lua lua/
```
