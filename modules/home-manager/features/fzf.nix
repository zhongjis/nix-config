{pkgs, ...}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --type f";
    defaultOptions = [
      "--height 40%"
      "--prompt ⟫"
    ];

    changeDirWidget.command = "fd --type d";
    changeDirWidget.options = [
      "--preview 'tree -C {} | head -200'"
    ];
  };

  home.packages = with pkgs; [
    fd
  ];
}
