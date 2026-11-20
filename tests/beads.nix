# Run: nix eval --impure --raw --expr '(import ./tests/beads.nix).drvPath'
let
  inputs = (builtins.getFlake (toString ../.)).inputs;
  pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  lib = pkgs.lib;
  evaluate = packages: personal: settings:
    (inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = packages;
      extraSpecialArgs = {
        inherit inputs;
        aiProfileHelpers.isPersonal = personal;
      };
      modules = [
        ../custom-home-manager-options/beads
        ../modules/home-manager/features/ai-tools/common/beads.nix
        ({lib, ...}: {
          options.sops.secrets = lib.mkOption {type = lib.types.attrs;};
          config = {
            sops.secrets.linear_api_key.path = "/run/secrets/test-linear";
            home = {
              username = "beads-test";
              homeDirectory = "/home/beads-test";
              stateVersion = "25.11";
            };
          };
        })
        settings
      ];
    }).config;
  disabled = evaluate pkgs false {};
  cli = evaluate pkgs false {programs.beads.enable = true;};
  enabled = {
    programs.beads = {
      enable = true;
      server.enable = true;
    };
  };
  linux = evaluate pkgs true enabled;
  darwin = evaluate inputs.nixpkgs.legacyPackages.aarch64-darwin false enabled;
  custom = evaluate pkgs false (enabled // {xdg.dataHome = "/home/beads-test/data";});
  service = linux.systemd.user.services.beads;
  agent = darwin.launchd.agents.beads.config;
  prime = builtins.readFile linux.home.file.beads-prime.source;
in
  assert !(disabled.systemd.user.services ? beads);
  assert !(disabled.home.file ? beads-prime);
  assert !(cli.home.sessionVariables ? BEADS_DIR);
  assert linux.home.sessionVariables.BEADS_DIR == "/home/beads-test/.local/share/beads/global/.beads";
  assert linux.home.sessionVariables.BEADS_DOLT_SHARED_SERVER == "1";
  assert linux.home.sessionVariables.LINEAR_TEAM_ID == "bfeea957-f57b-4c82-afd7-1b3eca55fd0e";
  assert lib.hasInfix "LINEAR_API_KEY=" linux.home.sessionVariablesExtra;
  assert lib.hasInfix "/run/secrets/test-linear" linux.home.sessionVariablesExtra;
  assert !(darwin.home.sessionVariables ? LINEAR_TEAM_ID);
  assert linux.programs.beads.settings."linear.state_map.started" == "open";
  assert linux.programs.beads.settings."linear.state_map.completed" == "closed";
  assert linux.programs.beads.settings."linear.state_map.canceled" == "closed";
  assert service.Service.Type == "oneshot";
  assert service.Service.RemainAfterExit;
  assert !(service.Service ? Restart);
  assert lib.hasInfix "dolt stop" service.Service.ExecStop;
  assert service.Service.WorkingDirectory == "/home/beads-test/.local/share/beads/global";
  assert service.Install.WantedBy == ["default.target"];
  assert agent.RunAtLoad && !agent.KeepAlive;
  assert agent.EnvironmentVariables.BEADS_DIR == darwin.home.sessionVariables.BEADS_DIR;
  assert agent.EnvironmentVariables.BEADS_DOLT_SHARED_SERVER == "1";
  assert builtins.length agent.ProgramArguments == 1;
  assert "${linux.home.homeDirectory}/${linux.home.file.beads-prime.target}" == "${linux.home.sessionVariables.BEADS_DIR}/PRIME.md";
  assert darwin.home.file.beads-prime.source == linux.home.file.beads-prime.source;
  assert custom.home.sessionVariables.BEADS_DIR == "/home/beads-test/data/beads/global/.beads";
  assert !(lib.hasInfix "herdr" (lib.toLower prime));
  assert !(lib.hasInfix "orchestration" (lib.toLower prime));
  assert lib.hasInfix "Never run `bd dolt push`" prime;
    pkgs.writeText "beads-prime-checked" prime
