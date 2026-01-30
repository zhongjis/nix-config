{lib, ...}: {
  vim.autocomplete.blink-cmp = {
    enable = true;

    friendly-snippets.enable = true;

    setupOpts = {
      appearance.use_nvim_cmp_as_default = true;
      cmdline = {
        completion.menu.auto_show = true;
        keymap.preset = "inherit"; # Inherit keymaps from default mode (including <C-y> confirm)
      };

      completion = {
        trigger = {
          show_on_keyword = true;
          show_on_trigger_character = true;
          show_on_insert_on_trigger_character = true;
        };
        accept = {
          auto_brackets.enabled = false;
          dot_repeat = true;
          create_undo_point = true;
        };
        list = {
          selection = {
            auto_insert = true;
          };
        };
        menu = {
          auto_show = true;
          draw = {
            columns = [
              ["kind_icon"]
              ["label" "label_description" (lib.mkLuaInline ''gap = 1'')]
              ["kind"]
            ];
            treesitter = ["lsp"];
          };
        };
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 250;
        };
      };
      snippets = {
        preset = "luasnip";
      };
      signature = {
        enabled = true;
      };
      sources = {
        default = [
          "snippets"
          "lsp"
          "path"
        ];
        providers = {};
      };
    };

    mappings = {
      next = "<C-n>";
      previous = "<C-p>";
      confirm = "<C-y>";
      complete = "<C-Space>";
    };

    sourcePlugins = {
      ripgrep.enable = true;
      spell.enable = true;
    };
  };

  vim.snippets.luasnip.enable = true;
}
