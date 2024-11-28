{pkgs, ...}: {
  # nh
  programs.nh = {
    enable = true;
    package = pkgs.nh;
    clean.enable = true;
    clean.extraArgs = "--keep-since 30d --keep 10";
    flake = "/home/zshen/personal/nix-config";
  };
}
