{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # GitHub CLI
    gh

    # MongoDB shell
    mongosh
  ];
}
