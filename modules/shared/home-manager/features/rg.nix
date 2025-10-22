{pkgs, ...}: {
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--max-columns-preview"
      "--colors=line:style:bold"
      "--hidden"
      "--smart-case"
      "--follow"
      "--glob '!node_modules/*'"
      "--glob '!.direnv/*'"
      "--glob '!.git/*'"
      "--color=always"
      "--line-number"
      "--column"
      "--sort=path"
      "--max-columns=200"
    ];
  };
}
