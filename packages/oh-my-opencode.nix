{
  pkgs,
  lib,
  base,
}: let
  baseWithoutLicense = base.overrideAttrs (oldAttrs: {
    meta = builtins.removeAttrs (oldAttrs.meta or {}) ["license"];
  });

  aliasNames = [
    "oh-my-opencode"
    "oh-my-openagent"
    "omo"
    "lazycodex"
    "lazycodex-ai"
  ];
in
  pkgs.symlinkJoin {
    name = "oh-my-opencode";
    paths = [baseWithoutLicense];
    nativeBuildInputs = [pkgs.makeWrapper];

    postBuild = ''
      for name in ${lib.escapeShellArgs aliasNames}; do
        rm -f "$out/bin/$name"
        makeWrapper ${baseWithoutLicense}/bin/oh-my-opencode "$out/bin/$name" \
          --set OMO_INVOCATION_NAME "$name"
      done
    '';

    meta =
      (baseWithoutLicense.meta or {})
      // {
        mainProgram = "oh-my-opencode";
      };
  }
