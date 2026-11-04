{config, ...}: {
  # Tailscale for tailnet access and Funnel; sign in once with `sudo tailscale up`.
  services.tailscale = {
    enable = true;
    # Opens UDP 41641 for direct peer connections.
    openFirewall = true;
    # Lets the primary user run `tailscale funnel` and `tailscale serve` without sudo.
    extraSetFlags = ["--operator=${config._module.args.currentSystemUser}"];
  };
}
