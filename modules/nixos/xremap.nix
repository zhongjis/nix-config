{ lib, config, inputs }:

{
  options = {
    xremap.enable =
      lib.mkEnableOption "enable xremap";
  };

  config = lib.mkIf config.xremap.enalbe {
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
