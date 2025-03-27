# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  modulesPath,
  lib,
  pkgs,
  meta,
  currentSystemUser,
  ...
}: let
  sopsFile = ../../secrets/homelab.yaml;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/shared
    ../../modules/nixos

    ./disk-config.nix
  ];
  # ++ lib.optional (builtins.pathExists ./hardware-configuration-${meta.hostname}.nix) ./hardware-configuration-${meta.hostname}.nix;

  myNixOS.bundles.general-k3s.enable = true;
  stylix.enable = false;

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = meta.hostname;

  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Fixes for longhorn
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  virtualisation.docker.logDriver = "json-file";

  sops.secrets = {
    k3s_token = {
      inherit sopsFile;
    };
  };

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets.k3s_token.path;
    extraFlags = toString ([
        "--write-kubeconfig-mode \"0644\""
        "--cluster-init"
        "--disable servicelb"
        "--disable traefik"
        "--disable local-storage"
      ]
      ++ (
        if meta.hostname == "homelab-0"
        then []
        else [
          "--server https://homelab-0:6443"
        ]
      ));
    clusterInit = meta.hostname == "homelab-0";
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDkA9QW9+SBK4dXpIj9nR9k49wuPdjlMwLvSacM9ExM zhongjie.x.shen@gmail.com"
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${currentSystemUser}" = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    # Created using mkpasswd
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDkA9QW9+SBK4dXpIj9nR9k49wuPdjlMwLvSacM9ExM zhongjie.x.shen@gmail.com"
    ];
  };
  programs.fish.enable = true;

  services.openssh.enable = true;

  networking.firewall.enable = false;

  system.stateVersion = "24.05"; # Did you read the comment?
}
