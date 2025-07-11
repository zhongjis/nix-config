{pkgs, ...}: {
  vim.extraPackages = with pkgs; [
    fzf
    ripgrep
  ];

  vim.telescope = {
    enable = true;
    extensions = [
      {
        name = "fzf";
        packages = [pkgs.vimPlugins.telescope-fzf-native-nvim];
        setup = {fzf = {fuzzy = true;};};
      }
    ];
  };
}
