{
  vim.utility.oil-nvim.enable = true;

  vim.utility.oil-nvim.setupOpts = {
    view_options = {
      show_hidden = true;
    };
  };

  vim.keymaps = [
    {
      key = "<leader>o";
      mode = "n";
      silent = true;
      action = "<cmd>Oil<cr>";
    }
  ];
}
