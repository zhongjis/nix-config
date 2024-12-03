{pkgs, ...}: {
  myHomeManager.bundles.general.enable = true;
  myHomeManager.hyprland.monitors = {
    "desc:Thermotrex Corporation TL140BDXP02-0" = {
      width = 2560;
      height = 1440;
      refreshRate = 60.;
      x = 0;
      y = 0;
      scale = 1.25;
    };
    "desc:LG Electronics LG ULTRAGEAR 009NTDV4B698" = {
      width = 3440;
      height = 1440;
      refreshRate = 143.92;
      x = 2560;
      y = 0;
    };
    "desc:Dell Inc. DELL P2419H 78NFR63" = {
      width = 1920;
      height = 1080;
      refreshRate = 60.;
      x = 6000;
      y = 0;
      rotate = 1;
    };
  };

  myHomeManagerLinux.bundles.linux.enable = true;
  myHomeManagerLinux.bundles.hyprland.enable = true;

  programs.git.userName = "zhongjis";
  programs.git.userEmail = "zhongjie.x.shen@gmail.com";

  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  home.stateVersion = "23.11"; # Please read the comment before changing.
  home.packages = with pkgs; [];
  home.file = {};
}
