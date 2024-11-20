{
  pkgs,
  lib,
  config,
  ...
}: let
  uptime-sh = pkgs.writeShellScript "uptime-nixos.sh" ./scripts/uptime-nixos.sh;
in {
  options = {
    hyprland.enable =
      lib.mkEnableOption "enables hyprland";
  };

  config = lib.mkIf config.hyprland.enable {
    # hyprland
    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;

    home.pointerCursor = {
      gtk.enable = true;
      # x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

    gtk = {
      enable = true;

      theme = {
        package = pkgs.flat-remix-gtk;
        name = "Flat-Remix-GTK-Grey-Darkest";
      };

      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };

      font = {
        name = "Sans";
        size = 11;
      };
    };

    # hyprlock
    programs.hyprlock = {
      enable = true;
      extraConfig = ''
        $background = rgb(070B11)
        $foreground = rgb(EFF2F5)
        $color0 = rgb(070B11)
        $color1 = rgb(19293E)
        $color2 = rgb(1C2C40)
        $color3 = rgb(4B4C5E)
        $color4 = rgb(4F4E60)
        $color5 = rgb(547191)
        $color6 = rgb(9DA4AA)
        $color7 = rgb(E0E5E8)
        $color8 = rgb(9DA0A2)
        $color9 = rgb(213753)
        $color10 = rgb(263A56)
        $color11 = rgb(65657D)
        $color12 = rgb(696880)
        $color13 = rgb(7096C1)
        $color14 = rgb(D2DBE2)
        $color15 = rgb(E0E5E8)

        ${builtins.readFile ./hyprlock.conf}

        # Uptime
        label {
            monitor =
            text = cmd[update:60000] echo "<b> "$(uptime -p || ${uptime-sh})" </b>"
            color = rgb(184, 192, 224)
            font_size = 11
            font_family = JetBrains Mono Nerd Font 10
            position = 0, -1000
            halign = center
            valign = top
        }


      '';
    };
  };
}
