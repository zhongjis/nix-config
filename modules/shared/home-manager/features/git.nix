{
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;

    # configure username and email in home.nix
    userName = lib.mkDefault "zhongjis";
    userEmail = lib.mkDefault "zhongjie.x.shen@gmail.com";

    aliases = {};
    attributes = [];

    # TODO: fancy signature for commits and tags
    # signing = {
    #   format = "ssh";
    # };

    diff-so-fancy = {
      enable = true;
      markEmptyLines = false;
    };

    extraConfig = {
      core = {
        compression = 9;
        whitespace = "error";
        preloadindex = true;
      };
      init = {
        defaultBranch = "main";
      };
      status = {
        branch = true;
        showStash = true;
        showUntrackedFiles = "all";
      };
      diff = {
        context = 3;
        renames = "copies";
        interHunkContext = 10;
      };
      push = {
        autoSetupRemote = true;
        default = "current";
        followTags = true;
      };
      pull = {
        default = "current";
        rebase = true;
      };
      rebase = {
        autoStash = true;
        missingCommitsCheck = true;
      };
      branch.sort = "-committerdate";
      tag.sort = "-taggerdate";
    };
  };

  programs.zsh.shellAliases = {
    gs = "git status --short";

    ga = "git add";
    gc = "git commit";

    gp = "git push";
    gu = "git pull"; # git update

    gl = "git log";
    glo = "git log --oneline";
    gb = "git branch";

    gd = "git diff";
  };

  home.packages = with pkgs; [
    # git-agecrypt
  ];
}
