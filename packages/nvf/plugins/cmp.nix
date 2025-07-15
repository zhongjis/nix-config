{pkgs, ...}: {
  vim.autocomplete.blink-cmp = {
    enable = true;
    friendly-snippets.enable = true;
    setupOpts = {
      cmdline.completion.menu.auto_show = true;
      signature.enabled = true;
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
