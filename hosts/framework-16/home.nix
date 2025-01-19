{pkgs,inputs, currentSystem,...}: {
  myHomeManager.bundles.general.enable = true;
  myHomeManager.direnv.enable = true;
  myHomeManager.hyprland.monitors = {
    "desc:BOE 0x0BC9" = {
      width = 2560;
      height = 1600;
      refreshRate = 165.;
      x = 0;
      y = 0;
      scale = 1.25;
      # scale = 1.;
    };
    "desc:LG Electronics LG ULTRAGEAR 009NTDV4B698" = {
      width = 3440;
      height = 1440;
      refreshRate = 143.92;
      # refreshRate = 60.;
      # x = 2560
      x = 2048;
      y = 0;
    };
    "desc:Dell Inc. DELL P2419H 78NFR63" = {
      width = 1920;
      height = 1080;
      refreshRate = 60.;
      # x = 6000;
      x = 5488;
      y = 0;
      rotate = 1;
    };
  };
  myHomeManager.hyprland.workspaces = {   
      "1" = {
        monitorId = 0;
        autostart = with pkgs; [];
      };
      # game
      "9" = {
        monitorId = 1;
        autostart =  with pkgs; [];
      };
      # zen
      "10" = {
        monitorId = 1;
        autostart =  with pkgs; [
          (lib.getExe vesktop) 
        ] ++ [
          (lib.getExe inputs.zen-browser.packages."${currentSystem}".default)
        ];
      };
  };

  myHomeManagerLinux.bundles.linux.enable = true;
  myHomeManagerLinux.bundles.hyprland.enable = true;

  programs.git.userName = "zhongjis";
  programs.git.userEmail = "zhongjie.x.shen@gmail.com";

  home.username = "zshen";
  home.homeDirectory = "/home/zshen";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [];
  home.file = {};
}
