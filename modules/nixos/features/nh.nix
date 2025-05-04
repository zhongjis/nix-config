{...}: {
  # nh
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 14d --keep 10";
    flake = "/home/zshen/personal/nix-config";
  };
}
