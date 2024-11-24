{
  lib,
  config,
  inputs,
  ...
}: {
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
}
