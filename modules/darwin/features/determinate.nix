{lib, ...}: let
  nixConfig = import ../../shared/nix-settings.nix {inherit lib;};
  determinateCustomConf = builtins.toFile "determinate-nix-custom.conf" nixConfig.determinateCustomConf;
in {
  # NOTE: disable for determinate nix
  # https://github.com/DeterminateSystems/determinate
  nix.enable = false;
  nix.optimise.automatic = false;
  nix.gc.automatic = false;

  # Determinate Nix owns /etc/nix/nix.conf and includes nix.custom.conf.
  # Render the shared Nix settings there during activation.
  system.activationScripts.extraActivation.text = ''
    printf >&2 'configuring Determinate Nix custom config...\n'
    /bin/mkdir -p /etc/nix
    /usr/bin/install -m 0644 ${determinateCustomConf} /etc/nix/nix.custom.conf
  '';
}
