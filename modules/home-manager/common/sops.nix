{inputs, ...}: {
  imports = [
    inputs.sops.nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFiles = ../../../secrets.yaml;
    validateSopsFiles = false;

    age = {
      path = "%r/.config/sops/age/keys.txt";
    };
  };
}
