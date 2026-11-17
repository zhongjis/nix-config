# Run: nix eval --impure --raw --expr '(import ./tests/rtk.nix).drvPath'
let
  flake = builtins.getFlake (toString ../.);
  config = flake.homeConfigurations."zshen@framework-16".config;
  lib = flake.inputs.nixpkgs.lib;
  rtkPackage = flake.inputs.llm-agents.packages.${builtins.currentSystem}.rtk;
  activation = config.home.activation.rtkCodex;
  hasPackage = builtins.any (package: package.drvPath == rtkPackage.drvPath) config.home.packages;
in
  assert config.programs.codex.rtk.enable;
  assert hasPackage;
  assert config.home.file ? "rtk/config.toml";
  assert activation.after == ["linkGeneration"];
  assert lib.hasInfix "CODEX_HOME=/home/zshen/.codex" activation.data;
  assert lib.hasInfix "init -g --codex" activation.data;
  assert lib.hasInfix "@/home/zshen/.codex/RTK.md" config.programs.codex.context;
    config.home.activationPackage
