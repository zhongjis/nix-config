# Run: nix eval --impure --raw --expr '(import ./tests/ai-tools.nix).drvPath'
let
  flake = builtins.getFlake (toString ../.);
  selfSrc = builtins.path {
    path = ../.;
    name = "nix-config-test-src";
    filter = path: type:
      type
      != "socket"
      && !(builtins.elem (baseNameOf path) [".git" ".codegraph"]);
  };
  inputs =
    flake.inputs
    // {
      self = flake // {outPath = selfSrc;};
    };
  system = builtins.currentSystem;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      flake.overlays.modifications
      flake.overlays.stable-packages
    ];
  };
  lib = pkgs.lib;
  myLib = import ../lib {
    inherit inputs;
    nixpkgs = inputs.nixpkgs;
    overlays = flake.overlays;
  };

  evaluate = settings:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs myLib;
        currentSystemName = "test-host";
      };
      modules = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.stylix.homeModules.stylix
        ({config, ...}: {
          imports = [
            (myLib.extendModule {
              path = ../modules/home-manager/features/ai-tools;
              extraOptions.myHomeManager.ai-tools.enable = lib.mkEnableOption "enable my ai-tools configuration";
              configExtension = body: (lib.mkIf config.myHomeManager.ai-tools.enable body);
            })
          ];
          stylix.enable = false;
          sops.age.keyFile = "/tmp/test-age-key";
          home = {
            username = "ai-tools-test";
            homeDirectory = "/home/ai-tools-test";
            stateVersion = "25.11";
          };
        })
        settings
      ];
    }).config;

  hasPackage = cfg: pkg:
    builtins.any (installed: installed.drvPath == pkg.drvPath) cfg.home.packages;

  disabled = evaluate {
    myHomeManager.ai-tools.enable = false;
  };

  disabledWithOptIn = evaluate {
    myHomeManager.ai-tools = {
      enable = false;
      claude-code.enable = true;
      copilot.enable = true;
      opencode.enable = true;
      factory.enable = true;
      omp.enable = true;
    };
  };

  defaultPersonal = evaluate {
    myHomeManager.aiProfile = "personal";
    myHomeManager.ai-tools.enable = true;
  };

  defaultWork = evaluate {
    myHomeManager.aiProfile = "work";
    myHomeManager.ai-tools.enable = true;
  };

  workOverrides = evaluate {
    myHomeManager.aiProfile = "work";
    myHomeManager.ai-tools = {
      enable = true;
      claude-code.enable = true;
      copilot.enable = false;
    };
  };

  onlyClaude = evaluate {
    myHomeManager.aiProfile = "personal";
    myHomeManager.ai-tools = {
      enable = true;
      agy.enable = false;
      codex.enable = false;
      pi.enable = false;
    };
  };

  noClaude = evaluate {
    myHomeManager.aiProfile = "personal";
    myHomeManager.ai-tools = {
      enable = true;
      claude-code.enable = false;
    };
  };

  optInAll = evaluate {
    myHomeManager.aiProfile = "personal";
    myHomeManager.ai-tools = {
      enable = true;
      copilot.enable = true;
      factory.enable = true;
      omp.enable = true;
      opencode.enable = true;
    };
  };

  missingProfile = evaluate {
    myHomeManager.ai-tools.enable = true;
  };
in
  # Master switch off: nothing leaks and aiProfile need not be set.
  assert !disabled.programs.antigravity-cli.enable;
  assert !disabled.programs.claude-code.enable;
  assert !disabled.programs.codex.enable;
  assert !disabled.programs.github-copilot-cli.enable;
  assert !disabled.programs.pi.enable;
  assert !disabled.programs.opencode.enable;
  assert !disabled.programs."oh-my-pi".enable;
  assert !disabled.programs.mcp.enable;
  assert !disabled.programs.beads.enable;
  assert !(disabled.home.activation ? claudeCodePermissions);
  assert !(disabled.home.activation ? seedCodexConfig);
  assert !(disabled.home.file ? ".pi/agent/lsp.json");
  assert !(disabled.home.file ? ".pi/agent/intercom/config.json");
  assert !(disabled.home.file ? ".omo/omo.jsonc");
  assert !(disabled.home.file ? ".factory/AGENTS.md");
  assert !(disabled.sops.secrets ? opencode_zen_api_key);
  assert !(disabled.sops.secrets ? context7_api_key);
  assert !(hasPackage disabled pkgs.nodejs_24);
  assert builtins.isString disabled.home.activationPackage.drvPath;
  # Master switch off overrides explicit child enables.
  assert !disabledWithOptIn.programs.claude-code.enable;
  assert !disabledWithOptIn.programs.github-copilot-cli.enable;
  assert !disabledWithOptIn.programs.opencode.enable;
  assert !disabledWithOptIn.programs."oh-my-pi".enable;
  assert !(disabledWithOptIn.home.file ? ".factory/AGENTS.md");
  assert !(disabledWithOptIn.home.file ? ".omo/omo.jsonc");
  # Personal profile defaults: agy, claude-code, codex, pi on; copilot and rest off.
  assert defaultPersonal.programs.antigravity-cli.enable;
  assert defaultPersonal.programs.claude-code.enable;
  assert defaultPersonal.programs.codex.enable;
  assert !defaultPersonal.programs.github-copilot-cli.enable;
  assert defaultPersonal.programs.pi.enable;
  assert !defaultPersonal.programs.opencode.enable;
  assert !defaultPersonal.programs."oh-my-pi".enable;
  assert !(defaultPersonal.home.file ? ".factory/AGENTS.md");
  assert !(defaultPersonal.home.file ? ".omo/omo.jsonc");
  assert defaultPersonal.home.file ? ".pi/agent/lsp.json";
  assert defaultPersonal.programs.mcp.enable;
  assert defaultPersonal.programs.beads.enable;
  assert hasPackage defaultPersonal pkgs.nodejs_24;
  # Work profile defaults: pi and copilot on; agy, claude-code, codex, and rest off.
  assert !defaultWork.programs.antigravity-cli.enable;
  assert !defaultWork.programs.claude-code.enable;
  assert !defaultWork.programs.codex.enable;
  assert defaultWork.programs.github-copilot-cli.enable;
  assert defaultWork.programs.pi.enable;
  assert !defaultWork.programs.opencode.enable;
  assert !defaultWork.programs."oh-my-pi".enable;
  assert !(defaultWork.home.activation ? claudeCodePermissions);
  assert !(defaultWork.home.activation ? seedCodexConfig);
  assert defaultWork.home.file ? "/home/ai-tools-test/.copilot/copilot-instructions.md";
  assert defaultWork.home.file ? "/home/ai-tools-test/.copilot/mcp-config.json";
  assert !(defaultWork.home.file ? "/home/ai-tools-test/.copilot/config.json");
  assert builtins.isString defaultWork.home.activationPackage.drvPath;
  # Work profile can still override individual tool defaults.
  assert workOverrides.programs.claude-code.enable;
  assert !workOverrides.programs.github-copilot-cli.enable;
  assert workOverrides.programs.pi.enable;
  # Selective disable: disabling agy/codex/pi leaves claude-code and shared nodejs_24 intact.
  assert !onlyClaude.programs.antigravity-cli.enable;
  assert onlyClaude.programs.claude-code.enable;
  assert !onlyClaude.programs.codex.enable;
  assert !onlyClaude.programs.pi.enable;
  assert !(onlyClaude.home.activation ? seedCodexConfig);
  assert !(onlyClaude.home.file ? ".pi/agent/lsp.json");
  assert !(onlyClaude.home.file ? ".pi/agent/intercom/config.json");
  assert !(onlyClaude.sops.secrets ? opencode_zen_api_key);
  assert hasPackage onlyClaude pkgs.nodejs_24;
  # Disabling claude-code removes its activation hooks and session variables.
  assert !noClaude.programs.claude-code.enable;
  assert !(noClaude.home.activation ? claudeCodePermissions);
  assert !(noClaude.home.activation ? claudeCodeDirenvHooks);
  assert !(noClaude.home.sessionVariables ? CLAUDE_CODE_DISABLE_AUTO_MEMORY);
  assert noClaude.programs.codex.enable;
  # Opt-in tools activate cleanly when enabled.
  assert optInAll.programs.github-copilot-cli.enable;
  assert optInAll.programs.opencode.enable;
  assert optInAll.home.file ? ".omo/omo.jsonc";
  assert optInAll.programs."oh-my-pi".enable;
  assert optInAll.home.file ? ".factory/AGENTS.md";
  assert optInAll.sops.secrets ? openrouter_api_key;
  # Enabling ai-tools without aiProfile triggers the assertion.
  assert !(builtins.tryEval missingProfile.home.activationPackage.drvPath).success;
    defaultPersonal.home.activationPackage
