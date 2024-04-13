{ lib, config, inputs }:

{
  options = {
    xremap.enable = 
      lib.mkEnableOption "enables xremap";
  };

  config = lib.mkIf config.xremap.enable {
    imports = [
      inputs.xremap-flake.homeManagerModules.default
    ];

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
