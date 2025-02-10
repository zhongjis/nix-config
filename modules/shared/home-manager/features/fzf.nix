{pkgs, ...}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --type f";
    defaultOptions = [
      "--height 40%"
      "--prompt ⟫"
    ];

    changeDirWidgetCommand = "fd --type d";
    changeDirWidgetOptions = [
      "--preview 'tree -C {} | head -200'"
    ];
  };

  home.packages = with pkgs; [
    fd
  ];
}
