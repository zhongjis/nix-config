{
  modulesPath,
  lib,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/shared
    ../../modules/nixos
    ./disk-config.nix
  ];

  myNixOS.sops.enable = true;
  myNixOS.nh.enable = true;

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.git
    pkgs.neovim
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHzczNq8Vc/nrjB1pzIhE2+N/O9kEu+naEhD4BAEjokg zhongjie.x.shen@gmail.com"
  ];

  system.stateVersion = "24.05";
}
