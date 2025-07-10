{...}: {
  vim.autocmds.highlight-yank = {
    enable = true;
    desc = "Highlight when yanking (copying) text";
    group = "kickstart-highlight-yank";
    callback = {
      _type = "lua-inline";
      expr = ''
        function()
          vim.highlight.on_yank()
        end
      '';
    };
  };
}
