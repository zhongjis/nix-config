{inputs, ...}: {
  imports = [
    inputs.xremap-flake.nixosModules.default
  ];

  services.xremap = {
    withHypr = true;
    userName = "zshen";
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
