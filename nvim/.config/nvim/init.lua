----------------------------
-- Basics
----------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
-- Code files: no wrap, but make horizontal scrolling smooth and show indicators
-- when lines extend past the viewport (›/‹ in the gutter).
-- Prose filetypes (markdown, text, gitcommit) override this below — see FileType autocmd.
vim.opt.wrap = false
vim.opt.sidescroll = 1       -- scroll 1 char at a time instead of half-screen jump
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8    -- horizontal version of scrolloff — keeps cursor 8 cols from edge
vim.opt.list = true
vim.opt.listchars = { extends = "›", precedes = "‹", tab = "  " }

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"

-- Persistent undo across sessions — lets you undo even after closing and reopening a file.
-- Neovim stores undo history in ~/.local/state/nvim/undo/ automatically.
vim.opt.undofile = true
vim.opt.swapfile = false

-- Splits open to the right and below, which matches the natural reading direction
-- (default is left and above, which most people find counterintuitive).
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Default is 4000ms (4s). 250ms speeds up gitsigns, autoread checktime,
-- and other CursorHold-based features.
vim.opt.updatetime = 250

-- Auto-reload files changed outside Neovim (e.g. by Claude Code).
-- autoread alone only checks on certain events — the autocmd below
-- forces a check when you switch back to Neovim or move the cursor.
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "checktime",
})

-- Prose filetypes: wrap long lines at word boundaries with preserved indent.
-- Code keeps the global `nowrap` + horizontal-scroll setup; prose gets proper wrapping.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit", "mail" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true    -- break at word boundaries, not mid-word
    vim.opt_local.breakindent = true  -- wrapped lines inherit indent of the original
    vim.opt_local.showbreak = "↪ "    -- visual marker at the start of continuation lines
  end,
})

-- Clear search highlight with Esc (no more :noh)
vim.keymap.set("n", "<Esc>", function()
  vim.cmd("nohlsearch")
end, { desc = "Clear search highlight" })

-- Window navigation handled by vim-tmux-navigator (see plugin below)

-- Copy file path + line range to clipboard (for pasting into Claude Code)
-- Visual select lines, press gy → copies "src/main.rs#L14-17"
-- Normal mode gy → copies "src/main.rs#L14" (just the cursor line)
vim.keymap.set("v", "gy", function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  local ref = path .. "#L" .. start_line .. "-" .. end_line
  vim.fn.setreg("+", ref)
  vim.notify(ref, vim.log.levels.INFO)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end, { desc = "Copy path#lines to clipboard" })

vim.keymap.set("n", "gy", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  local ref = path .. "#L" .. vim.fn.line(".")
  vim.fn.setreg("+", ref)
  vim.notify(ref, vim.log.levels.INFO)
end, { desc = "Copy path#line to clipboard" })

----------------------------
-- Diagnostics
----------------------------
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2 },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Always-works diagnostic nav (0.11+ API)
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "Prev diagnostic" })

----------------------------
-- Formatting (conform.nvim — configured below in plugins)
----------------------------

-- Manual format keymap — set here, conform handles the actual formatting.
-- Conform is configured in the plugin section with format_on_save built in.
vim.keymap.set("n", "<leader>F", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer (async)" })

-- Ctrl+S: save (Terminal-friendly; run `stty -ixon` in your shell)
-- Conform's format_on_save handles formatting before write.
vim.keymap.set("n", "<C-s>", "<cmd>write<cr>", { desc = "Save" })

----------------------------
-- lazy.nvim bootstrap
----------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

----------------------------
-- Plugins
----------------------------
require("lazy").setup({
  -- Icons (shared dependency — used by lualine, bufferline, oil, neo-tree, trouble, render-markdown)
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Theme
  {
    "Mofiqul/dracula.nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("dracula")
    end,
  },

  -- Treesitter (safe on first install)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        return
      end
      configs.setup({
        -- Pin the languages you actually use so a fresh machine just works.
        -- Without this you'd need to manually :TSInstall each one.
        ensure_installed = {
          "rust",
          "lua",
          "typescript",
          "javascript",
          "tsx",
          "solidity",
          "toml",
          "json",
          "markdown",
          "css",
          "html",
          "yaml",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local t = require("telescope")
      local b = require("telescope.builtin")
      t.setup({})

      vim.keymap.set("n", "<leader>ff", b.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", b.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", b.buffers, { desc = "Buffers" })

      -- Better than quickfix open/close: searchable diagnostics list
      vim.keymap.set("n", "<leader>d", function()
        b.diagnostics({
          layout_strategy = "vertical",
          layout_config = { height = 0.85, width = 0.9 },
        })
      end, { desc = "Diagnostics (project)" })
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = {
          theme = "dracula",
          section_separators = "",
          component_separators = "",
        },
        sections = {
          lualine_c = { { "filename", path = 1 } }, -- 1 = relative path
        },
      })
    end,
  },

  -- Bufferline — IDE-style tab bar showing all open buffers at the top.
  -- Navigate with [b / ]b or click. Close with <leader>bd.
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    keys = {
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin buffer" },
      { "<leader>bd", "<cmd>bdelete<cr>", desc = "Close buffer" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
    },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = false, -- only show when 2+ buffers open
        offsets = {
          { filetype = "neo-tree", text = "Explorer", highlight = "Directory", separator = true },
        },
      },
    },
  },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Down>"] = cmp.mapping.select_next_item(),
          ["<Up>"] = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer", keyword_length = 3 },
          { name = "path" },
        },
      })

      -- Command line completion (`:` commands)
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "cmdline" },
          { name = "path" },
        },
      })

      -- Search completion (`/` and `?`)
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },

  -- Required by mason-lspconfig; server setup is done natively below
  { "neovim/nvim-lspconfig" },

  -- File explorer as a buffer — edit your filesystem like a normal file.
  -- `-` opens parent dir, you can rename/delete/create files by editing lines,
  -- then :w to apply. Feels like Vim instead of a sidebar tree.
  {
    "stevearc/oil.nvim",
    config = function()
      require("oil").setup({
        -- Show hidden files (dotfiles), you're in a terminal — you want to see them.
        view_options = {
          show_hidden = true,
        },
        -- Skip confirmation for simple operations (rename, create).
        -- Deletes still confirm. Keeps the workflow fast.
        skip_confirm_for_simple_edits = true,
        -- Float in center of screen instead of replacing the whole buffer.
        -- Less disorienting when you just want to grab a file quickly.
        float = {
          padding = 4,
          max_width = 100,
          max_height = 30,
        },
        -- Free up C-h so vim-tmux-navigator can use it for pane navigation.
        -- Oil's default C-h opens entry in horizontal split — use C-x instead.
        keymaps = {
          ["<C-h>"] = false,
          ["<C-l>"] = false,
          ["<C-x>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
        },
      })
      -- `-` to open parent directory (matches vim's built-in netrw convention)
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory (Oil)" })
      -- Floating variant for quick navigation without leaving your current layout
      vim.keymap.set("n", "<leader>-", require("oil").toggle_float, { desc = "Oil (float)" })
    end,
  },

  -- Shows available keybindings in a popup as you type.
  -- After pressing <leader>, wait ~300ms and a panel shows all continuations.
  -- Eliminates "what was that binding again?" entirely.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        -- Delay before popup appears (ms). Short enough to be useful,
        -- long enough to not flash on fast key sequences.
        delay = 300,
      })
    end,
  },

  -- Format on save via external tools (Prettier, StyLua, rustfmt).
  -- Replaces LSP-based formatting — faster, more predictable, project-aware.
  -- Falls back to LSP formatting for languages without a dedicated formatter.
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          typescript = { "prettierd", "prettier", stop_after_first = true },
          typescriptreact = { "prettierd", "prettier", stop_after_first = true },
          javascript = { "prettierd", "prettier", stop_after_first = true },
          javascriptreact = { "prettierd", "prettier", stop_after_first = true },
          json = { "prettierd", "prettier", stop_after_first = true },
          css = { "prettierd", "prettier", stop_after_first = true },
          html = { "prettierd", "prettier", stop_after_first = true },
          markdown = { "prettierd", "prettier", stop_after_first = true },
          yaml = { "prettierd", "prettier", stop_after_first = true },
          lua = { "stylua" },
          rust = { "rustfmt" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_format = "fallback",
        },
      })
    end,
  },

  -- Auto-close and auto-rename JSX/HTML tags.
  -- Type <div> and </div> appears. Rename <div> to <span> and closing tag updates.
  { "windwp/nvim-ts-autotag", event = "InsertEnter", opts = {} },

  -- Auto-close brackets, quotes, parens as you type.
  -- Also handles the annoying case of pressing Enter between {} to expand them.
  -- Treesitter-aware: won't insert a closing quote inside a string.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({
        check_ts = true, -- Use treesitter to check for pairs (smarter in strings/comments)
      })
      -- Integrate with nvim-cmp so confirming a completion also triggers autopairs.
      -- Without this, completing `function` wouldn't auto-insert `()`.
      local ok_cmp, cmp = pcall(require, "cmp")
      if ok_cmp then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end,
  },

  -- Surround text objects with brackets, quotes, tags, etc.
  -- `ysaw"` = surround a word with quotes.  `cs"'` = change " to '.
  -- `ds"` = delete surrounding quotes.  `ysa"t` = surround quotes with <tag>.
  -- Visual mode: select text, then `S"` to wrap in quotes.
  -- Works with any delimiter and supports custom surrounds.
  {
    "kylechui/nvim-surround",
    version = "^4.0.0",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },

  -- AI inline completions — ghost text suggestions as you type.
  -- First run: authenticate with :Copilot auth (opens browser).
  -- No conflict: cmp uses arrow keys, Copilot owns Tab.
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          -- Don't let Copilot set Tab directly — we handle it below
          -- so Tab falls through to normal indent when no suggestion is visible.
          keymap = {
            accept = false,
            dismiss = "<C-]>",
            next = "<C-n>",
            prev = "<C-p>",
          },
        },
        panel = { enabled = false },
        filetypes = { TelescopePrompt = false },
      })
      -- Tab: accept Copilot suggestion if visible, otherwise normal Tab
      vim.keymap.set("i", "<Tab>", function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { desc = "Accept Copilot or indent" })
    end,
  },

  -- Markdown preview in a floating window — no browser needed.
  -- <leader>mp to toggle. Renders headings, lists, code blocks, tables inline.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "markdown" },
    keys = {
      { "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown preview" },
    },
    opts = {},
  },

  -- Sidebar file tree with git status indicators.
  -- Toggle with <leader>e, find current file with <leader>E.
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "File tree" },
      { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in tree" },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = { visible = true },
      },
      window = { width = 35 },
    },
  },

  -- Label-based jumping — press `s` + two chars and labels appear on all matches.
  -- Massively faster than f/t for navigating visible text. Also enhances
  -- f, t, F, T with labels when multiple matches exist.
  {
    "folke/flash.nvim",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "<leader>s",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
    },
  },

  -- Organized diagnostics, references, and TODO list in a persistent panel.
  -- Better than quickfix for working through errors — filterable, navigable,
  -- and integrates with LSP references and todo-comments.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle focus=true<cr>", desc = "Diagnostics (Trouble)" },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0 focus=true<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle focus=true<cr>", desc = "Quickfix (Trouble)" },
    },
    opts = {},
  },

  -- Auto-install LSP servers, formatters, and linters.
  -- No more manual `brew install rust-analyzer` — Mason handles it.
  -- mason-lspconfig bridges Mason with nvim-lspconfig so servers auto-start.
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "rust_analyzer", "ts_ls", "lua_ls", "eslint", "solidity_ls_nomicfoundation" },
        -- No-op default handler — we use vim.lsp.config + vim.lsp.enable below.
        -- Without this, mason-lspconfig would also call lspconfig[server].setup(),
        -- resulting in each server being configured twice.
        handlers = { function() end },
      })
    end,
  },

  -- Auto-install formatters and linters (non-LSP tools that Mason manages).
  -- mason-lspconfig only handles LSP servers; this handles the rest.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = { "prettierd", "stylua" },
      })
    end,
  },

  -- Seamless Ctrl-h/j/k/l navigation between vim splits and tmux panes.
  -- Requires matching if-shell bindings in ~/.tmux.conf.
  { "christoomey/vim-tmux-navigator", lazy = false },

  -- snacks.nvim — collection of QoL modules from folke.
  -- Each module is independently toggled. Only enabled ones load.
  {
    "folke/snacks.nvim",
    lazy = false,
    keys = {
      -- Lazygit popup (Ctrl-a g in tmux style, but <leader>gg in nvim)
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>gl",
        function()
          Snacks.lazygit.log()
        end,
        desc = "Lazygit log (current file)",
      },
      -- Open current file/line on GitHub
      {
        "<leader>gB",
        function()
          Snacks.gitbrowse()
        end,
        desc = "Open in GitHub",
        mode = { "n", "v" },
      },
      -- Floating terminal
      {
        "<C-/>",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle terminal",
        mode = { "n", "t" },
      },
      -- LSP-aware file rename
      {
        "<leader>cR",
        function()
          Snacks.rename.rename_file()
        end,
        desc = "Rename file (LSP)",
      },
      -- Notification history
      {
        "<leader>un",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification history",
      },
    },
    opts = {
      -- Smooth scrolling for Ctrl-D, Ctrl-U, etc.
      scroll = {
        enabled = true,
        animate = { duration = { step = 15, total = 150 } },
      },
      -- Pretty notifications replacing vim.notify.
      notifier = { enabled = true, timeout = 3000 },
      -- Better vim.ui.input — nicer rename/input prompts.
      input = { enabled = true },
      -- Disable heavy features (treesitter, LSP, etc.) on large files.
      -- Prevents Neovim from freezing when you accidentally open a bundle.
      bigfile = { enabled = true, size = 1.5 * 1024 * 1024 }, -- 1.5 MB
      -- Faster file loading on startup.
      quickfile = { enabled = true },
      -- Indent guides — shows vertical lines at each indent level.
      -- Especially useful for deeply nested JSX/TSX.
      indent = {
        enabled = true,
        animate = { enabled = false }, -- static lines, no animation overhead
      },
      words = { enabled = false },
      -- Lazygit integration — opens in a floating terminal.
      lazygit = { enabled = true },
      -- Open current file/line in GitHub (or other git hosts).
      gitbrowse = { enabled = true },
      -- LSP-aware file rename — updates imports across the project.
      rename = { enabled = true },
      -- Floating terminal.
      terminal = { enabled = true },
    },
  },

  -- Replaces the command line, messages, and popupmenu with a modern floating UI.
  -- Gives you autocomplete in `:` commands, nicer search feedback, and routes
  -- LSP progress/messages through the notification system.
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = {
        -- Let noice handle LSP hover/signature rendering instead of cmp/lspconfig defaults.
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      -- Use snacks.nvim for notifications (already configured above) instead of noice's built-in.
      -- Avoids double-notification UI.
      routes = {
        { filter = { event = "notify", find = "No information available" }, opts = { skip = true } },
      },
      presets = {
        bottom_search = true, -- search stays at bottom (less disorienting)
        command_palette = true, -- command line floats centered like VS Code
        long_message_to_split = true, -- long messages go to a split instead of flooding the screen
        lsp_doc_border = true, -- border around hover/signature docs
      },
    },
  },
})

----------------------------
-- LSP (Neovim 0.11+ native style)
----------------------------
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "K", vim.lsp.buf.hover, "Hover docs")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})

-- Configure servers
vim.lsp.config("rust_analyzer", { capabilities = capabilities })
vim.lsp.config("ts_ls", { capabilities = capabilities })
vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  settings = { Lua = { diagnostics = { globals = { "vim" } } } },
})
vim.lsp.config("eslint", {
  capabilities = capabilities,
  -- Don't let ESLint format — Prettier (via conform) handles formatting.
  -- This prevents double-formatting conflicts on save.
  settings = {
    format = false,
  },
  on_attach = function(client, _)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
})
vim.lsp.config("solidity_ls_nomicfoundation", { capabilities = capabilities })

-- Enable servers
vim.lsp.enable({ "rust_analyzer", "ts_ls", "lua_ls", "eslint", "solidity_ls_nomicfoundation" })
