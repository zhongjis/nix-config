{
  modulesPath,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/shared
    ../../modules/nixos

    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  myNixOS.bundles.general-server.enable = true;
  myNixOS.freshrss.enable = true;
  myNixOS.dify.enable = true;

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [
    22 # ssh
    80 # http
    443 # https
  ];

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.git
    pkgs.neovim
    pkgs.unzip
  ];

  networking.hostName = "vultr-lab"; # Define your hostname.

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zshen = {
    isNormalUser = true;
    description = "Jason";
    extraGroups = ["networkmanager" "wheel" "docker"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHzczNq8Vc/nrjB1pzIhE2+N/O9kEu+naEhD4BAEjokg zhongjie.x.shen@gmail.com"
    ];
  };
  programs.zsh.enable = true;

  system.stateVersion = "24.05";
}
