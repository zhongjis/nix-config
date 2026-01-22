{lib, ...}: {
  vim.keymaps = [
    # Clear search highlight
    {
      key = "<Esc>";
      mode = "n";
      silent = true;
      action = "<cmd>nohlsearch<CR>";
    }

    # Better indenting (stay in visual mode)
    {
      key = "<";
      mode = ["v"];
      silent = true;
      action = "<gv";
    }
    {
      key = ">";
      mode = ["v"];
      silent = true;
      action = ">gv";
    }

    # Paste without yanking in visual mode
    {
      key = "p";
      mode = ["x"];
      silent = true;
      action = "\"_dP";
    }

    # Diagnostics
    {
      key = "<leader>e";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.diagnostic.open_float";
      };
      desc = "Show diagnostic float";
    }
    {
      key = "[d";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.diagnostic.goto_prev";
      };
      desc = "Previous diagnostic";
    }
    {
      key = "]d";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.diagnostic.goto_next";
      };
      desc = "Next diagnostic";
    }
    {
      key = "<leader>q";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.diagnostic.setloclist";
      };
      desc = "Diagnostics to loclist";
    }

    # Window navigation
    {
      key = "<C-h>";
      mode = ["n"];
      silent = true;
      action = "<C-w>h";
      desc = "Go to left window";
    }
    {
      key = "<C-j>";
      mode = ["n"];
      silent = true;
      action = "<C-w>j";
      desc = "Go to lower window";
    }
    {
      key = "<C-k>";
      mode = ["n"];
      silent = true;
      action = "<C-w>k";
      desc = "Go to upper window";
    }
    {
      key = "<C-l>";
      mode = ["n"];
      silent = true;
      action = "<C-w>l";
      desc = "Go to right window";
    }

    # Window resize
    {
      key = "<C-Up>";
      mode = ["n"];
      silent = true;
      action = "<cmd>resize +2<CR>";
      desc = "Increase window height";
    }
    {
      key = "<C-Down>";
      mode = ["n"];
      silent = true;
      action = "<cmd>resize -2<CR>";
      desc = "Decrease window height";
    }
    {
      key = "<C-Left>";
      mode = ["n"];
      silent = true;
      action = "<cmd>vertical resize -2<CR>";
      desc = "Decrease window width";
    }
    {
      key = "<C-Right>";
      mode = ["n"];
      silent = true;
      action = "<cmd>vertical resize +2<CR>";
      desc = "Increase window width";
    }

    # Buffer navigation
    {
      key = "<S-h>";
      mode = ["n"];
      silent = true;
      action = "<cmd>bprevious<CR>";
      desc = "Previous buffer";
    }
    {
      key = "<S-l>";
      mode = ["n"];
      silent = true;
      action = "<cmd>bnext<CR>";
      desc = "Next buffer";
    }
    {
      key = "<leader>bd";
      mode = ["n"];
      silent = true;
      action = "<cmd>bdelete<CR>";
      desc = "Delete buffer";
    }
    {
      key = "<leader>bD";
      mode = ["n"];
      silent = true;
      action = "<cmd>bdelete!<CR>";
      desc = "Force delete buffer";
    }

    # Move lines up/down
    {
      key = "<A-j>";
      mode = ["n"];
      silent = true;
      action = "<cmd>m .+1<CR>==";
      desc = "Move line down";
    }
    {
      key = "<A-k>";
      mode = ["n"];
      silent = true;
      action = "<cmd>m .-2<CR>==";
      desc = "Move line up";
    }
    {
      key = "<A-j>";
      mode = ["i"];
      silent = true;
      action = "<Esc><cmd>m .+1<CR>==gi";
      desc = "Move line down";
    }
    {
      key = "<A-k>";
      mode = ["i"];
      silent = true;
      action = "<Esc><cmd>m .-2<CR>==gi";
      desc = "Move line up";
    }
    {
      key = "<A-j>";
      mode = ["v"];
      silent = true;
      action = ":m '>+1<CR>gv=gv";
      desc = "Move selection down";
    }
    {
      key = "<A-k>";
      mode = ["v"];
      silent = true;
      action = ":m '<-2<CR>gv=gv";
      desc = "Move selection up";
    }

    # Better navigation (keep cursor centered)
    {
      key = "<C-d>";
      mode = ["n"];
      silent = true;
      action = "<C-d>zz";
      desc = "Scroll down (centered)";
    }
    {
      key = "<C-u>";
      mode = ["n"];
      silent = true;
      action = "<C-u>zz";
      desc = "Scroll up (centered)";
    }
    {
      key = "n";
      mode = ["n"];
      silent = true;
      action = "nzzzv";
      desc = "Next search result (centered)";
    }
    {
      key = "N";
      mode = ["n"];
      silent = true;
      action = "Nzzzv";
      desc = "Prev search result (centered)";
    }

    # Quick save
    {
      key = "<C-s>";
      mode = ["n" "i" "v"];
      silent = true;
      action = "<cmd>w<CR>";
      desc = "Save file";
    }

    # Quick quit
    {
      key = "<leader>qq";
      mode = ["n"];
      silent = true;
      action = "<cmd>qa<CR>";
      desc = "Quit all";
    }

    # Better join (keep cursor position)
    {
      key = "J";
      mode = ["n"];
      silent = true;
      action = "mzJ`z";
      desc = "Join lines (keep cursor)";
    }

    # Select all
    {
      key = "<C-a>";
      mode = ["n"];
      silent = true;
      action = "gg<S-v>G";
      desc = "Select all";
    }

    # Format
    {
      key = "<leader>cf";
      mode = ["n" "v"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = ''
          function()
            require("conform").format({ async = true, lsp_fallback = true })
          end
        '';
      };
      desc = "Format buffer";
    }

    # LSP keymaps (common ones)
    {
      key = "gd";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.lsp.buf.definition";
      };
      desc = "Go to definition";
    }
    {
      key = "gD";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.lsp.buf.declaration";
      };
      desc = "Go to declaration";
    }
    {
      key = "gi";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.lsp.buf.implementation";
      };
      desc = "Go to implementation";
    }
    {
      key = "gr";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.lsp.buf.references";
      };
      desc = "Go to references";
    }
    {
      key = "K";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.lsp.buf.hover";
      };
      desc = "Hover documentation";
    }
    {
      key = "<leader>ca";
      mode = ["n" "v"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.lsp.buf.code_action";
      };
      desc = "Code action";
    }
    {
      key = "<leader>cr";
      mode = ["n"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.lsp.buf.rename";
      };
      desc = "Rename symbol";
    }
    {
      key = "<C-k>";
      mode = ["i"];
      silent = true;
      action = {
        _type = "lua-inline";
        expr = "vim.lsp.buf.signature_help";
      };
      desc = "Signature help";
    }
  ];
}
