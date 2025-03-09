{inputs, ...}: {
  imports = [
    inputs.xremap-flake.homeManagerModules.default
  ];

  services.xremap = {
    config = {
      modmap = [
        {
          name = "main remaps";
          remap = {
            "CapsLock" = "esc";
          };
        }
      ];
    };
  };
}
