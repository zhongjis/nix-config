{lib, ...}: {
  vim.keymaps = [
    {
      key = "<Esc>";
      mode = "n";
      silent = true;
      action = "<cmd>nohlsearch<CR>";
    }
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
    {
      key = "p";
      mode = ["x"];
      silent = true;
      action = "\"_dp";
    }
    {
      key = "<leader>e";
      mode = ["n"];
      silent = true;
      action = "vim.diagnostic.open_float";
    }
  ];
}
