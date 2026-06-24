# Pure-data registry of custom packages assembled from this directory.
#
# Consumed by:
#   - flake-parts/packages.nix  -> builds the perSystem `packages` outputs
#   - .github/workflows/update-packages.yml -> discovers updatable packages
#
# Keep this file free of `inputs`, `pkgs`, and `lib` so it can be evaluated
# standalone (e.g. `nix eval --impure --expr 'import ./packages/registry.nix'`)
# without forcing the whole flake.
#
# Per-entry fields:
#   path       (required) path to the package's .nix file (a function of
#                         `{pkgs, lib, ...extraArgs}`).
#   extraArgs  (optional) list of extra argument names the file needs beyond
#                         `{pkgs, lib}`; resolved in packages.nix via argSources.
#   linuxOnly  (optional) when true, only assembled on Linux systems. Use for
#                         files that `throw` at import on unsupported platforms.
#   updatable  (optional) when true, the update workflow tracks this package
#                         (the package must declare `passthru.updateScript`).
#   selfUpdateScript (optional) when true, `passthru.updateScript` is a fully
#                         self-contained launcher (getExe of a
#                         writeShellApplication). The workflow builds and execs
#                         it directly, skipping nix-update -- whose read-only
#                         metadata eval can choke on IFD (e.g. bun2nix cargoDeps).
{
  opencode-morph-fast-apply = {
    path = ./opencode-morph-fast-apply.nix;
    extraArgs = ["bun2nix"];
    updatable = true;
    selfUpdateScript = true;
  };
  context-mode = {
    path = ./context-mode;
    extraArgs = ["bun2nix"];
    # No updateScript upstream yet; registered but not tracked by the updater.
  };
  before-and-after = {
    path = ./before-and-after.nix;
    extraArgs = ["agentBrowser"];
    updatable = true;
  };
  splunk-as = {
    path = ./splunk-as.nix;
    updatable = true;
  };
  helium = {
    path = ./helium.nix;
    linuxOnly = true;
    updatable = true;
  };
  fincept-terminal = {
    path = ./fincept-terminal.nix;
    linuxOnly = true;
    updatable = true;
  };
}
