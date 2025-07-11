{pkgs, ...}: {
  # vim.autocomplete.nvim-cmp = {
  #   enable = true;
  #   mappings = {
  #     next = "<C-n>";
  #     previous = "<C-p>";
  #     confirm = "<C-y>";
  #     complete = "<C-Space>";
  #   };
  #   sourcePlugins = ["cmp-path" "cmp-nvim-lsp" "cmp-buffer" pkgs.vimPlugins.cmp_luasnip pkgs.vimPlugins.cmp-cmdline];
  # };

  vim.autocomplete.blink-cmp = {
    enable = true;
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
    friendly-snippets.enable = true;
  };

  vim.snippets.luasnip.enable = true;
}
