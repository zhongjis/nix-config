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
  };
}
