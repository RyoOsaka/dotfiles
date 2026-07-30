-- ~/.config/nvim/init.lua — Neovim 設定
-- プラグインマネージャに lazy.nvim を使用(初回起動時に自動インストール)

-- ----------------------------------------------------------------------
-- 基本オプション
-- ----------------------------------------------------------------------
local opt = vim.opt

opt.number = true              -- 行番号
opt.relativenumber = false     -- 相対行番号(好みで true に)
opt.cursorline = true          -- カーソル行をハイライト
opt.wrap = false               -- 折り返さない
opt.scrolloff = 8              -- スクロール時に上下 8 行の余白
opt.signcolumn = "yes"         -- サインカラムを常に表示

opt.tabstop = 4                -- タブ幅
opt.shiftwidth = 4             -- インデント幅
opt.expandtab = true           -- タブをスペースに展開
opt.smartindent = true

opt.ignorecase = true          -- 検索時に大文字小文字を無視
opt.smartcase = true           -- 大文字を含むときだけ区別
opt.incsearch = true
opt.hlsearch = true

opt.undofile = true            -- 永続 undo
opt.swapfile = false
opt.backup = false

opt.termguicolors = true
opt.clipboard = "unnamedplus"  -- システムクリップボード連携(WSL は win32yank か wl-clipboard 推奨)
opt.mouse = "a"
opt.updatetime = 300
opt.splitright = true
opt.splitbelow = true

-- ----------------------------------------------------------------------
-- キーマップ
-- ----------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "検索ハイライトを消す" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "保存" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "終了" })
map("n", "<C-h>", "<C-w>h", { desc = "左のウィンドウへ" })
map("n", "<C-j>", "<C-w>j", { desc = "下のウィンドウへ" })
map("n", "<C-k>", "<C-w>k", { desc = "上のウィンドウへ" })
map("n", "<C-l>", "<C-w>l", { desc = "右のウィンドウへ" })
map("v", "<", "<gv", { desc = "インデント解除して選択維持" })
map("v", ">", ">gv", { desc = "インデントして選択維持" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "選択行を下へ移動" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "選択行を上へ移動" })

-- ----------------------------------------------------------------------
-- lazy.nvim のブートストラップ
-- ----------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ----------------------------------------------------------------------
-- プラグイン
-- ----------------------------------------------------------------------
require("lazy").setup({
  -- カラースキーム
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  -- ステータスライン
  {
    "nvim-lualine/lualine.nvim",
    opts = { options = { theme = "tokyonight" } },
  },

  -- ファジーファインダー
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "ファイル検索" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>",  desc = "全文検索 (要 ripgrep)" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>",    desc = "バッファ一覧" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>",  desc = "ヘルプ検索" },
    },
  },

  -- シンタックスハイライト
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",  -- main ブランチは新API(configs モジュール廃止)のため master に固定
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "bash", "python", "javascript", "json", "yaml", "markdown" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- git 差分表示
  { "lewis6991/gitsigns.nvim", opts = {} },

  -- 括弧の自動補完
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- コメントトグル (gcc / gc)
  { "numToStr/Comment.nvim", opts = {} },

  -- キーマップのヒント表示
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
}, {
  -- lazy.nvim 自体の設定
  checker = { enabled = false },
})

