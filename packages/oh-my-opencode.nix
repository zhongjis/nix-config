{
  pkgs,
  lib,
  base,
}: let
  aliasNames = [
    "oh-my-opencode"
    "oh-my-openagent"
    "omo"
    "omo-agent-toolkit"
    "lazycodex"
    "lazycodex-ai"
  ];
in
  pkgs.symlinkJoin {
    name = "oh-my-opencode";
    paths = [base];
    nativeBuildInputs = [pkgs.makeWrapper];

    postBuild = ''
      for name in ${lib.escapeShellArgs aliasNames}; do
        rm -f "$out/bin/$name"
        makeWrapper ${base}/bin/oh-my-opencode "$out/bin/$name" \
          --set OMO_INVOCATION_NAME "$name"
      done
    '';

    meta = base.meta or {};
  }
