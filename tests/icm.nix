# Run: nix eval --impure --raw --expr '(import ./tests/icm.nix).drvPath'
let
  inputs = (builtins.getFlake (toString ../.)).inputs;
  pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  lib = pkgs.lib;
  evaluate = packages: settings:
    (inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = packages;
      extraSpecialArgs = {inherit inputs;};
      modules = [
        ../custom-home-manager-options/icm
        ({lib, ...}: {
          # The ICM module contributes these values to the custom Pi module.
          options.programs.pi = {
            context = lib.mkOption {
              type = lib.types.lines;
              default = "";
            };
            skills = lib.mkOption {
              type = lib.types.attrsOf lib.types.path;
              default = {};
            };
          };
          config.home = {
            username = "icm-test";
            homeDirectory = "/home/icm-test";
            stateVersion = "25.11";
          };
        })
        settings
      ];
    }).config;
  disabled = evaluate pkgs {};
  daemon = evaluate pkgs {programs.icm.daemon.enable = true;};
  integrated = evaluate pkgs {
    programs.pi.icm.enable = true;
    programs.icm.daemon.enable = true;
  };
  standaloneIntegration = evaluate pkgs {programs.pi.icm.enable = true;};
  custom = evaluate pkgs {
    programs.icm = {
      daemon = {
        enable = true;
        address = "[::1]:19876";
      };
      package = pkgs.hello;
      settings.store.path = "/home/icm-test/memories.db";
    };
  };
  relative = evaluate pkgs {
    programs.icm = {
      daemon.enable = true;
      settings.store.path = ".icm/project.db";
    };
  };
  empty = evaluate pkgs {
    programs.icm = {
      daemon.enable = true;
      settings.store.path = "";
    };
    xdg.dataHome = "/home/icm-test/data";
  };
  descriptor = config: builtins.fromJSON config.xdg.configFile."icm/daemon.json".text;
  darwinPkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
  darwin = evaluate darwinPkgs {programs.icm.daemon.enable = true;};
  darwinDisabled = evaluate darwinPkgs {};
  missingPackage = evaluate pkgs {
    programs.icm = {
      daemon.enable = true;
      package = null;
    };
  };
  remote = evaluate pkgs {programs.icm.daemon.address = "0.0.0.0:9876";};
  expectedPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.icm;
  service = daemon.systemd.user.services.icm;
  hasPackage = config: package:
    builtins.any (installed: installed.drvPath == package.drvPath) config.home.packages;
in
  assert !(disabled.systemd.user.services ? icm);
  assert !(disabled.home.file ? "icm/config.toml");
  assert !(disabled.xdg.configFile ? "icm/daemon.json");
  assert !(hasPackage disabled expectedPackage);
  assert daemon.programs.icm.package.drvPath == expectedPackage.drvPath;
  assert hasPackage daemon expectedPackage;
  assert daemon.programs.icm.settings == {};
  assert daemon.home.file."icm/config.toml".source != null;
  assert descriptor daemon
  == {
    url = "http://127.0.0.1:9876/mcp";
    database = "/home/icm-test/.local/share/icm/memories.db";
  };
  assert "${daemon.home.homeDirectory}/${daemon.xdg.configFile."icm/daemon.json".target}" == "${daemon.xdg.configHome}/icm/daemon.json";
  assert service.Service.ExecStart == ["${lib.getExe expectedPackage} --db /home/icm-test/.local/share/icm/memories.db serve --http 127.0.0.1:9876"];
  assert service.Service.WorkingDirectory == daemon.home.homeDirectory;
  assert service.Service.Restart == "on-failure";
  assert service.Service.RestartSec == "5s";
  assert service.Unit.After == ["network.target"];
  assert service.Install.WantedBy == ["default.target"];
  assert integrated.programs.icm.settings.extraction
  == {
    store_raw = false;
    summarizer.provider = "auto";
  };
  assert standaloneIntegration.programs.icm.settings == integrated.programs.icm.settings;
  assert hasPackage standaloneIntegration expectedPackage;
  assert standaloneIntegration.home.file."icm/config.toml".source != null;
  assert !(standaloneIntegration.systemd.user.services ? icm);
  assert !(standaloneIntegration.xdg.configFile ? "icm/daemon.json");
  assert descriptor custom
  == {
    url = "http://[::1]:19876/mcp";
    database = "/home/icm-test/memories.db";
  };
  assert custom.systemd.user.services.icm.Service.ExecStart == ["${lib.getExe pkgs.hello} --db /home/icm-test/memories.db serve --http '[::1]:19876'"];
  assert custom.programs.icm.settings.store.path == "/home/icm-test/memories.db";
  assert (descriptor relative).database == "/home/icm-test/.icm/project.db";
  assert relative.systemd.user.services.icm.Service.ExecStart == ["${lib.getExe expectedPackage} --db /home/icm-test/.icm/project.db serve --http 127.0.0.1:9876"];
  assert relative.programs.icm.settings.store.path == ".icm/project.db";
  assert (descriptor empty).database == "/home/icm-test/data/icm/memories.db";
  assert empty.systemd.user.services.icm.Service.ExecStart == ["${lib.getExe expectedPackage} --db /home/icm-test/data/icm/memories.db serve --http 127.0.0.1:9876"];
  assert empty.programs.icm.settings.store.path == "";
  assert !(builtins.tryEval darwin.home.activationPackage.drvPath).success;
  assert !(darwinDisabled.systemd.user.services ? icm);
  assert darwinDisabled.programs.icm.settings == {};
  assert !(darwinDisabled.xdg.configFile ? "icm/daemon.json");
  assert !(builtins.tryEval missingPackage.home.activationPackage.drvPath).success;
  assert !(builtins.tryEval remote.programs.icm.daemon.address).success;
    daemon.home.file."icm/config.toml".source
