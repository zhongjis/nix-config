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

  ## Indentation (default - will be overridden per-filetype)
  vim.options.tabstop = 4; # Number of spaces that a <Tab> in the file counts for
  vim.options.softtabstop = 4; # Number of spaces that a <Tab> counts for while performing editing operations
  vim.options.shiftwidth = 4; # Number of spaces to use for each step of (auto)indent
  vim.options.expandtab = true; # Convert tabs to spaces
  vim.options.smartindent = true; # Enable smart indentation
  vim.options.shiftround = true; # Round indent to multiple of shiftwidth

  ## Search
  vim.options.hlsearch = true; # Enable search highlighting
  vim.options.incsearch = true; # Enable incremental search
  vim.options.ignorecase = true; # Ignore case when searching
  vim.options.smartcase = true; # Override ignorecase if search contains uppercase letters

  # Files and backups
  vim.options.swapfile = false; # Disable swap file creation
  vim.options.backup = false; # Disable backup file creation
  vim.options.writebackup = false; # Don't create backup before overwriting

  vim.options.undofile = true; # Enable persistent undo
  vim.options.undodir = lib.mkLuaInline "os.getenv(\"HOME\") .. \"/.vim/undodir\""; # Set undo directory

  # Clipboard
  vim.options.clipboard = "unnamedplus"; # Use the system clipboard

  # Command behavior
  vim.options.inccommand = "split"; # Show effects of a command incrementally in a split window
  vim.options.showmode = false; # Do not display the current mode in the command line

  # Display and UI
  vim.options.wrap = false; # Disable line wrapping

  # Whitespace characters
  vim.options.list = true; # Show whitespace characters

  # Timing
  vim.options.updatetime = 50; # Set the delay (in milliseconds) before the swap file is written to disk
  vim.options.timeoutlen = 600; # Set the timeout length (in milliseconds) for a mapped sequence to complete

  # Scrolling
  vim.options.scrolloff = 10; # Keep 10 lines visible above/below the cursor
  vim.options.sidescrolloff = 8; # Keep 8 columns visible left/right of cursor

  ## QoL: Split behavior
  vim.options.splitbelow = true; # Horizontal splits open below
  vim.options.splitright = true; # Vertical splits open to the right
  vim.options.splitkeep = "screen"; # Keep text on screen when splitting

  ## QoL: Better editing experience
  vim.options.virtualedit = "block"; # Allow cursor to move where there is no text in visual block mode
  vim.options.confirm = true; # Confirm to save changes before exiting modified buffer
  vim.options.conceallevel = 2; # Hide markup for bold/italic in markdown
  vim.options.formatoptions = "jcroqlnt"; # Better formatting options

  ## QoL: Line handling
  vim.options.breakindent = true; # Wrapped lines continue visually indented
  vim.options.linebreak = true; # Break at word boundaries when wrap is on

  ## QoL: Folding (using treesitter)
  vim.options.foldlevel = 99; # Start with all folds open
  vim.options.foldlevelstart = 99;

  ## QoL: Better grep
  vim.options.grepformat = "%f:%l:%c:%m";
  vim.options.grepprg = "rg --vimgrep";

  ## QoL: Session options
  vim.options.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds";

  ## QoL: Mouse support
  vim.options.mouse = "a"; # Enable mouse in all modes
  vim.options.mousemoveevent = true; # Enable mouse move events

  ## QoL: Completion
  vim.options.completeopt = "menu,menuone,noselect"; # Better completion experience
  vim.options.wildmode = "longest:full,full"; # Command-line completion mode

  ## QoL: Fill characters for cleaner UI
  vim.options.fillchars = {
    foldopen = "";
    foldclose = "";
    fold = " ";
    foldsep = " ";
    diff = "╱";
    eob = " "; # Hide ~ at end of buffer
  };
}
