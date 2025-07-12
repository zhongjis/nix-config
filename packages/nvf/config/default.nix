{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./autocmds.nix
    ./keymaps.nix
    ./options.nix
    # ./usrcmds.nix
  ];
}
