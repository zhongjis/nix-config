{pkgs, ...}: {
  programs.secretspec = {
    enable = true;

    # Written to ~/.config/secretspec/config.toml
    settings.defaults = {
      provider = "bw"; # personal Bitwarden vault via the `bw` CLI
      profile = "development";
    };
  };

  # The `bw` provider shells out to the Bitwarden CLI
  home.packages = with pkgs; [
    bitwarden-cli
  ];
}
