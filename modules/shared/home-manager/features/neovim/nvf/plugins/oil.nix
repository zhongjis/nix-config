{
  vim.utility.oil-nvim.enable = true;

  vim.keymaps = [
    {
      key = "<leader>o";
      mode = "n";
      silent = true;
      action = "<cmd>Oil<cr>";
    }
  ];
}
