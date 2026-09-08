{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  neovimModule = inputs.stylix + "/modules/neovim/hm.nix";
  nvfModule = inputs.stylix + "/modules/neovim/nvf.nix";
  mkTarget = import (inputs.stylix + "/stylix/mk-target.nix") {
    humanName = (import (inputs.stylix + "/stylix/meta.nix") {inherit lib pkgs;}).neovim.name;
    name = "neovim";
  };
  # Temporarily migrate Stylix's lualine option until upstream supports the new nvf path.
  patchedNvfModule = builtins.toFile "stylix-nvf.nix" (builtins.replaceStrings
    ["lualine.theme"]
    ["lualine.setupOpts.options.theme"]
    (builtins.readFile nvfModule));
in {
  imports = [
    ../../shared/stylix_common.nix
    {
      disabledModules = [neovimModule];
      imports = [
        (import neovimModule {
          inherit mkTarget;
          lib =
            lib
            // {
              modules =
                lib.modules
                // {
                  importApply = module:
                    lib.modules.importApply (
                      if module == nvfModule
                      then patchedNvfModule
                      else module
                    );
                };
            };
        })
      ];
    }
  ];

  gtk.gtk4.theme = lib.mkForce config.gtk.theme;

  # stylix.cursor is applied only on Linux, but its x11/gtk targets still set
  # home.pointerCursor.*.enable on Darwin, where pointerCursor.name is never
  # defined -> eval error. Drop the cursor on Darwin so those blocks no-op.
  stylix.cursor = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (lib.mkForce null);

  stylix.targets = {
    waybar.enable = false;
    # neovim.enable = false;
    swaync.enable = false;
    hyprlock.enable = false;
    # kde.enable = false;
    rofi.enable = false;
    opencode.enable = false;
    zen-browser = {
      # enable = false;
      profileNames = lib.singleton "default";
    };
  };
}
