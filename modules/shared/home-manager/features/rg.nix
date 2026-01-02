{pkgs, ...}: {
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--max-columns-preview"
      "--colors=line:style:bold"
      "--smart-case"
      "--follow"
      "--line-number"
      "--column"
      "--max-columns=200"
    ];
  };
}
