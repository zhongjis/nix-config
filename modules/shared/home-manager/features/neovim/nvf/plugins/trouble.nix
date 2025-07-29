{
  vim.lsp.trouble.enable = true;

  vim.keymaps = [
    {
      key = "]x";
      mode = "n";
      silent = true;
      action = "<cmd> lua require(\"trouble\").next({ skip_groups = true, jump = true }) <cr>";
    }
    {
      key = "[x";
      mode = ["n"];
      silent = true;
      action = "<cmd> lua require(\"trouble\").prev({ skip_groups = true, jump = true }) <cr>";
    }
  ];
}
