{ lib, config, inputs, ... }:

{
  imports = [
    inputs.xremap-flake.homeManagerModules.default
  ];

  options = {
    xremap.enable =
      lib.mkEnableOption "enables xremap";
  };

  config = lib.mkIf config.xremap.enable {
    services.xremap = {
      withWlroots = true;
      yamlConfig = ''
        modmap:
          - name: main remaps
            remap:
              CapsLock: esc
      '';
    };
  };
}
