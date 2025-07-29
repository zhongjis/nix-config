{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./config
    ./plugins
  ];
  vim = {
    viAlias = true;
    vimAlias = true;

    theme.enable = true;
    statusline.lualine.enable = true;

    # spellcheck = {
    #   enable = true;
    #   programmingWordlist.enable = true;
    # };

    git.gitsigns = {
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

    notes.todo-comments.enable = true;
  };
}
