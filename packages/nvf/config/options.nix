{lib, ...}: {
  ## Leader keys
  vim.globals.mapleader = " "; # Set global leader key to whitespace
  vim.globals.maplocalleader = " "; # Set local leader key to whitespace

  ## Appearance
  vim.options.termguicolors = true; # Enable 24-bit RGB color in the terminal
  vim.options.number = true; # Show line numbers
  vim.options.relativenumber = true; # Show relative line numbers
  vim.options.colorcolumn = "80"; # Highlight the 80th column
  vim.options.signcolumn = "yes"; # Always show the sign column
  vim.options.cursorline = true; # Highlight the line with the cursor
  vim.options.cmdheight = 1;
  vim.options.pumheight = 10; # set max popup menu height
  vim.options.pumblend = 10;
  vim.globals.netrw_banner = 0; # turn off netrw banner

  ## Indentation
  vim.options.tabstop = 4; # Number of spaces that a <Tab> in the file counts for
  vim.options.softtabstop = 4; # Number of spaces that a <Tab> counts for while performing editing operations
  vim.options.shiftwidth = 4; # Number of spaces to use for each step of (auto)indent
  vim.options.expandtab = true; # Convert tabs to spaces
  vim.options.smartindent = true; # Enable smart indentation

  ## Search
  vim.options.hlsearch = true; # Enable search highlighting
  vim.options.incsearch = true; # Enable incremental search
  vim.options.ignorecase = true; # Ignore case when searching
  vim.options.smartcase = true; # Override ignorecase if search contains uppercase letters

  # Files and backups
  vim.options.swapfile = false; # Disable swap file creation
  vim.options.backup = false; # Disable backup file creation

  vim.options.undofile = true; # Enable persistent undo
  vim.options.undodir = lib.mkLualine "os.getenv(\"HOME\") .. \"/.vim/undodir\""; # Set undo directory

  # Clipboard
  vim.options.clipboard = "unnamedplus"; # Use the system clipboard

  # Command behavior
  vim.options.inccommand = "split"; # Show effects of a command incrementally in a split window
  vim.options.showmode = false; # Do not display the current mode in the command line

  # Display and UI
  vim.options.wrap = false; # Disable line wrapping

  # Whitespace characters
  vim.options.list = true; # Show whitespace characters
  # vim.options.listchars = { tab = "» ", trail = "·", nbsp = "␣" }; # Define how whitespace characters are displayed

  # Timing
  vim.options.updatetime = 50; # Set the delay (in milliseconds) before the swap file is written to disk
  vim.options.timeoutlen = 600; # Set the timeout length (in milliseconds) for a mapped sequence to complete

  # Scrolling
  vim.options.scrolloff = 10; # Keep 10 lines visible above/below the cursor
}
