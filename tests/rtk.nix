# Run: nix eval --impure --raw --expr '(import ./tests/rtk.nix).drvPath'
let
  flake = builtins.getFlake (toString ../.);
  config = flake.homeConfigurations."zshen@framework-16".config;
  lib = flake.inputs.nixpkgs.lib;
  rtkPackage = flake.inputs.llm-agents.packages.${builtins.currentSystem}.rtk;
  activation = config.home.activation.rtkCodexHook;
  hasPackage = builtins.any (package: package.drvPath == rtkPackage.drvPath) config.home.packages;
in
  assert config.programs.codex.rtk.enable;
  assert hasPackage;
  assert config.home.file ? "rtk/config.toml";
  assert activation.after == ["linkGeneration"];
  assert lib.hasInfix "/home/zshen/.codex/hooks.json" activation.data;
  assert lib.hasInfix "/bin/rtk hook codex" activation.data;
  assert !(lib.hasInfix "rtk init" activation.data);
  assert lib.hasInfix "rtk bypass" config.programs.codex.context;
  assert !(lib.hasInfix "RTK.md" config.programs.codex.context);
    config.home.activationPackage
