-- Leader keys
vim.g.mapleader = " " -- Set global leader key to whitespace
vim.g.maplocalleader = " " -- Set local leader key to whitespace

-- Appearance
vim.opt.termguicolors = true -- Enable 24-bit RGB color in the terminal
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.colorcolumn = "80" -- Highlight the 80th column
vim.opt.signcolumn = "yes" -- Always show the sign column
vim.opt.cursorline = true -- Highlight the line with the cursor
vim.opt.cmdheight = 1
vim.opt.pumheight = 10 -- set max popup menu height
vim.opt.pumblend = 10
vim.g.netrw_banner = 0 -- turn off netrw banner

-- Indentation
vim.opt.tabstop = 4 -- Number of spaces that a <Tab> in the file counts for
vim.opt.softtabstop = 4 -- Number of spaces that a <Tab> counts for while performing editing operations
vim.opt.shiftwidth = 4 -- Number of spaces to use for each step of (auto)indent
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.smartindent = true -- Enable smart indentation

-- Search
vim.opt.hlsearch = true -- Enable search highlighting
vim.opt.incsearch = true -- Enable incremental search
vim.opt.ignorecase = true -- Ignore case when searching
vim.opt.smartcase = true -- Override ignorecase if search contains uppercase letters

-- Files and backups
vim.opt.swapfile = false -- Disable swap file creation
vim.opt.backup = false -- Disable backup file creation
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir" -- Set undo directory
vim.opt.undofile = true -- Enable persistent undo

-- Clipboard
vim.opt.clipboard = "unnamedplus" -- Use the system clipboard

-- Command behavior
vim.opt.inccommand = "split" -- Show effects of a command incrementally in a split window
vim.opt.showmode = false -- Do not display the current mode in the command line

-- Display and UI
vim.opt.wrap = false -- Disable line wrapping

-- Whitespace characters
vim.opt.list = true -- Show whitespace characters
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- Define how whitespace characters are displayed

-- Timing
vim.opt.updatetime = 50 -- Set the delay (in milliseconds) before the swap file is written to disk
vim.opt.timeoutlen = 600 -- Set the timeout length (in milliseconds) for a mapped sequence to complete

-- Scrolling
vim.opt.scrolloff = 10 -- Keep 10 lines visible above/below the cursor
