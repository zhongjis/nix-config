{
  pkgs,
  lib,
  ...
}: {
  vim = {
    theme.enable = false;
    # and more options as you see fit...

    statusline.lualine.enable = true;
    telescope.enable = true;
    autocomplete.nvim-cmp.enable = true;

    languages = {
      enableLSP = true;
      enableTreesitter = true;

      nix.enable = true;
      ts.enable = true;
      java.enable = true;
      terraform.enable = true;
      yaml.enable = true;
      python.enable = true;
    };
  };
}
