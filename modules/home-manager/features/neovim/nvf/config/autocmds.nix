{...}: {
  vim.augroups = [
    {
      enable = true;
      clear = true;
      name = "KickstartHighlightYank";
    }
    {
      enable = true;
      clear = true;
      name = "JenkinsFileFix";
    }
    {
      enable = true;
      clear = true;
      name = "TerraformFileFix";
    }
    {
      enable = true;
      clear = true;
      name = "HclFileFix";
    }
    {
      enable = true;
      clear = true;
      name = "AutoResize";
    }
    {
      enable = true;
      clear = true;
      name = "AutoSaveBuffer";
    }
    {
      enable = true;
      clear = true;
      name = "FiletypeIndent";
    }
    {
      enable = true;
      clear = true;
      name = "CheckOutsideChanges";
    }
    {
      enable = true;
      clear = true;
      name = "LastPosition";
    }
    {
      enable = true;
      clear = true;
      name = "CloseWithQ";
    }
    {
      enable = true;
      clear = true;
      name = "WrapSpell";
    }
  ];

  vim.autocmds = [
    # Highlight on yank
    {
      enable = true;
      desc = "Highlight when yanking (copying) text";
      event = ["TextYankPost"];
      group = "KickstartHighlightYank";
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
          end
        '';
      };
    }

    # Filetype detection fixes
    {
      enable = true;
      desc = "Set file type for JenkinsFile";
      event = ["BufNewFile" "BufRead"];
      group = "JenkinsFileFix";
      pattern = ["Jenkinsfile*"];
      command = "set filetype=groovy";
    }
    {
      desc = "Set file type for terraform";
      group = "TerraformFileFix";
      event = ["BufNewFile" "BufRead"];
      pattern = ["*.tf" "*.tfvars"];
      command = "set filetype=terraform";
    }
    {
      desc = "Set file type for hcl";
      group = "HclFileFix";
      event = ["BufNewFile" "BufRead"];
      pattern = ["*.hcl" ".terraformrc" "terraform.rc"];
      command = "set filetype=hcl";
    }
    {
      desc = "Set file type for terraform state";
      group = "HclFileFix";
      event = ["BufNewFile" "BufRead"];
      pattern = ["*.tfstate" "*.tfstate.backup"];
      command = "set filetype=json";
    }

    # Window management
    {
      desc = "Auto resize panes when window resized";
      group = "AutoResize";
      event = ["VimResized"];
      pattern = ["*"];
      command = "wincmd =";
    }

    # Auto-save
    {
      desc = "Auto save when leave buffer";
      group = "AutoSaveBuffer";
      event = ["BufLeave" "FocusLost"];
      pattern = ["*"];
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
            local filetype = vim.bo.filetype
            local buftype = vim.bo.buftype
            local excluded_filetypes = {
              oil = true,
              harpoon = true,
              trouble = true,
              TelescopePrompt = true,
              lazy = true,
              mason = true,
              [""] = true,
            }
            if not excluded_filetypes[filetype]
              and buftype ~= "nofile"
              and buftype ~= "prompt"
              and vim.bo.modified
            then
              vim.cmd("silent! wa")
            end
          end
        '';
      };
    }

    # Filetype-specific indentation (2 spaces)
    {
      desc = "Set 2-space indent for web/config files";
      group = "FiletypeIndent";
      event = ["FileType"];
      pattern = [
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
        "json"
        "jsonc"
        "yaml"
        "yml"
        "html"
        "css"
        "scss"
        "less"
        "vue"
        "svelte"
        "astro"
        "nix"
        "lua"
        "markdown"
        "xml"
        "graphql"
      ];
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
            vim.opt_local.tabstop = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.shiftwidth = 2
          end
        '';
      };
    }

    # Filetype-specific indentation (4 spaces - default for most)
    {
      desc = "Set 4-space indent for Java/Python/Scala";
      group = "FiletypeIndent";
      event = ["FileType"];
      pattern = [
        "java"
        "python"
        "scala"
        "sbt"
        "groovy"
        "kotlin"
        "go"
        "rust"
        "c"
        "cpp"
      ];
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
            vim.opt_local.tabstop = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.shiftwidth = 4
          end
        '';
      };
    }

    # Check for file changes outside of Neovim
    {
      desc = "Check for file changes when focusing buffer";
      group = "CheckOutsideChanges";
      event = ["FocusGained" "BufEnter" "CursorHold" "CursorHoldI"];
      pattern = ["*"];
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
            if vim.fn.getcmdwintype() == "" then
              vim.cmd("checktime")
            end
          end
        '';
      };
    }

    # Return to last edit position
    {
      desc = "Go to last location when opening a buffer";
      group = "LastPosition";
      event = ["BufReadPost"];
      pattern = ["*"];
      callback = {
        _type = "lua-inline";
        expr = ''
          function(event)
            local exclude_filetypes = { "gitcommit", "gitrebase", "svn", "hgcommit" }
            local buf = event.buf
            if vim.tbl_contains(exclude_filetypes, vim.bo[buf].filetype) or vim.b[buf].last_loc then
              return
            end
            vim.b[buf].last_loc = true
            local mark = vim.api.nvim_buf_get_mark(buf, '"')
            local lcount = vim.api.nvim_buf_line_count(buf)
            if mark[1] > 0 and mark[1] <= lcount then
              pcall(vim.api.nvim_win_set_cursor, 0, mark)
            end
          end
        '';
      };
    }

    # Close certain windows with 'q'
    {
      desc = "Close certain windows with q";
      group = "CloseWithQ";
      event = ["FileType"];
      pattern = [
        "help"
        "lspinfo"
        "man"
        "notify"
        "qf"
        "checkhealth"
        "startuptime"
        "PlenaryTestPopup"
      ];
      callback = {
        _type = "lua-inline";
        expr = ''
          function(event)
            vim.bo[event.buf].buflisted = false
            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
          end
        '';
      };
    }

    # Enable wrap and spell for text files
    {
      desc = "Enable wrap and spell for text files";
      group = "WrapSpell";
      event = ["FileType"];
      pattern = ["gitcommit" "markdown" "text"];
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
            vim.opt_local.wrap = true
            vim.opt_local.spell = true
          end
        '';
      };
    }
  ];
}
