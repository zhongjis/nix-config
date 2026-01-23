{
  pkgs,
  lib,
  ...
}: {
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        name = lib.mkDefault "zhongjis";
        email = lib.mkDefault "zhongjie.x.shen@gmail.com";
      };

      ui = {
        color = "auto";
        pager = "less -FRX";
        paginate = "auto";
        diff.format = "color-words";
        graph.style = "curved";
      };

      git = {
        auto-track-bookmarks = true;
        push-bookmark-prefix = "push-";
      };

      aliases = {
        st = ["status"];
        l = ["log"];
        lg = ["log" "--graph"];
        co = ["checkout"];
        n = ["new"];
        d = ["diff"];
        ds = ["diff" "--stat"];
        s = ["status"];
      };

      revset-aliases = {
        "my-commits" = "mine()";
      };
    };
  };

  programs.zsh.shellAliases = {
    j = "jj";
    jst = "jj status";
    jl = "jj log";
    jlg = "jj log --graph";
    jd = "jj diff";
    jn = "jj new";
    js = "jj squash";
    je = "jj edit";
    jco = "jj checkout";
    jb = "jj bookmark";
  };
}
