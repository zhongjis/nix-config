{
  vim.git.gitsigns = {
    enable = true;
    setupOpts = {
      signs = {
        add = {text = "▎";};
        change = {text = "▎";};
        delete = {text = "";};
        topdelete = {text = "";};
        changedelete = {text = "▎";};
        untracked = {text = "▎";};
      };
    };
  };
}
