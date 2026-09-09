# Run: nix eval --impure --raw --expr '(import ./tests/herdr.nix).drvPath'
let
  inputs = (builtins.getFlake (toString ../.)).inputs;
  pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  config =
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inherit inputs;};
      modules = [
        ../modules/home-manager/services/herdr
        {
          home.username = "herdr-test";
          home.homeDirectory = "/home/herdr-test";
          home.stateVersion = "25.11";
        }
      ];
    }).config;
  expected = {
    onboarding = false;
    theme.name = "terminal";
    terminal = {
      shell_mode = "auto";
      new_cwd = "follow";
    };
    keys.command = [
      {
        key = "prefix+f";
        type = "pane";
        command = "sessionizer";
      }
    ];
    ui = {
      prompt_new_tab_name = false;
      show_agent_labels_on_pane_borders = true;
      right_click_passthrough_modifier = "cmd";
      toast = {
        delivery = "system";
        herdr.position = "bottom-right";
      };
    };
    experimental.kitty_graphics = true;
    advanced.scrollback_limit_bytes = 10000000;
  };
  sessionizer = pkgs.writeScriptBin "sessionizer" ''
    ${builtins.readFile ../modules/home-manager/services/herdr/scripts/herdr-sessionizer.sh}
  '';
in
  assert pkgs.lib.assertMsg (config.programs.herdr.enable && config.programs.herdr.settings != {}) "native Herdr enable/settings absent";
  assert config.programs.herdr.package.drvPath == inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr.drvPath;
  assert builtins.any (package: package.drvPath == pkgs.jq.drvPath) config.home.packages;
  assert builtins.any (package: package.drvPath == sessionizer.drvPath) config.home.packages;
  assert config.programs.herdr.settings == expected;
    config.xdg.configFile."herdr/config.toml".source
