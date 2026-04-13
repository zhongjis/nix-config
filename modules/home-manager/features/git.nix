{
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;

    signing.format = "openpgp";

    # configure username and email in home.nix
    settings = {
      user = {
        name = lib.mkDefault "zhongjis";
        email = lib.mkDefault "zhongjie.x.shen@gmail.com";
      };
      core = {
        compression = 9;
        whitespace = "trailing-space,space-before-tab";
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
        renames = "copies";
        interHunkContext = 10;
      };
      push = {
        autoSetupRemote = true;
        default = "current";
        followTags = true;
      };
      pull = {
        rebase = true;
      };
      rebase = {
        autoStash = true;
        missingCommitsCheck = "warn";
      };
      branch.sort = "-committerdate";
      tag.sort = "-taggerdate";
      fetch = {
        prune = true;
        prunetags = true;
      };
      merge = {
        conflictstyle = "zdiff3";
      };
      rerere = {
        enabled = true;
      };
      commit = {
        verbose = true;
      };
      help = {
        autocorrect = "prompt";
      };
      transfer = {
        fsckobjects = true;
      };
    };

    # settings.attributes = [];

    # TODO: fancy signature for commits and tags
    # signing = {
    #   format = "ssh";
    # };
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

  programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;

    settings.markEmptyLines = false;
  };

  home.packages = with pkgs; [
    git-agecrypt
  ];
}
