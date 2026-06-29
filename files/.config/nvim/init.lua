-- Neovim config — rosé-pine + Kun Chen's published plugins on a lazy.nvim base.
-- (Kun's exact personal config isn't public; this mirrors his plugins + aesthetic.)
-- Managed in the dotfiles repo and symlinked to ~/.config/nvim via Home Manager.

-- Leader must be set before lazy.nvim loads.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ── Options ──────────────────────────────────────────────────────────────────
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.wrap = false
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.updatetime = 250
opt.timeoutlen = 400
opt.splitright = true
opt.splitbelow = true
opt.cursorline = true
opt.undofile = true
opt.clipboard = "unnamedplus"

-- ── Core keymaps ─────────────────────────────────────────────────────────────
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
-- window navigation (vim-style, mirrors the tmux pane keys)
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
-- keep selection when indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- ── Bootstrap lazy.nvim ──────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ──────────────────────────────────────────────────────────────────
require("lazy").setup({
  -- Theme — rosé-pine (moon), matching WezTerm + tmux
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({ variant = "moon" })
      vim.cmd.colorscheme("rose-pine-moon")
    end,
  },

  -- Syntax / highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
          "markdown", "markdown_inline", "python", "javascript",
          "typescript", "tsx", "go", "rust", "nix",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      map("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
      map("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
    end,
  },

  -- File explorer (sidebar tree) — toggle with <leader>e
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "File explorer (toggle)" },
      { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in tree" },
    },
    opts = {
      close_if_last_window = true,
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_default",
        filtered_items = { hide_dotfiles = false, hide_gitignored = false },
      },
      window = { width = 32 },
    },
  },

  -- Statusline + icons
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "rose-pine", globalstatus = true, section_separators = "", component_separators = "" } },
  },

  -- Git signs, comments, pairs, which-key
  { "lewis6991/gitsigns.nvim", opts = {} },
  { "numToStr/Comment.nvim", opts = {} },
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

  -- LSP + Mason
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({ ensure_installed = { "lua_ls" } })
      local caps = require("cmp_nvim_lsp").default_capabilities()
      -- Neovim 0.11+ native LSP config (nvim-lspconfig ships the server defs;
      -- avoids the deprecated require('lspconfig').<server>.setup() framework).
      vim.lsp.config("*", { capabilities = caps })
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })
      vim.lsp.enable("lua_ls")
      map("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
      map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
      map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
      map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
      map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Line diagnostics" })
    end,
  },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        }),
      })
    end,
  },

  -- Kun Chen's own Neovim plugins
  -- gen.nvim: generate text with LLMs (lazy-loaded on :Gen)
  { "kunchenguid/gen.nvim", cmd = "Gen" },
  -- comment-repl.nvim: run code in a REPL from a comment
  { "kunchenguid/comment-repl.nvim", event = "VeryLazy" },
}, {
  ui = { border = "rounded" },
  change_detection = { notify = false },
})
