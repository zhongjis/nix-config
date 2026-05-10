{inputs, ...}: {
  perSystem = {
    config,
    pkgs,
    lib,
    system,
    ...
  }: {
    packages = let
      inherit (lib) optionalAttrs;
      modelConfig = import ../lib/llamacpp-models.nix {inherit lib;};
      inherit (modelConfig) hfHome modelDir modelFiles modelPath modelRevision modelsDir;
      huggingfaceCli = pkgs.python3Packages.huggingface-hub;
      downloadModel = id: model: ''
        if [ ! -f ${lib.escapeShellArg (modelPath model)} ]; then
          echo "Downloading ${id}"
          ${lib.escapeShellArgs [
          "hf"
          "download"
          model.repo
          model.file
          "--revision"
          (modelRevision model)
          "--local-dir"
          (modelDir model)
          "--quiet"
        ]}
        else
          echo "Already downloaded ${id}"
        fi
      '';
    in
      {
        neovim =
          (inputs.nvf.lib.neovimConfiguration {
            inherit pkgs;
            modules = [../modules/home-manager/features/neovim/nvf];
          }).neovim;
      }
      // {
        oh-my-codex = inputs.llm-agents.packages.${system}.oh-my-codex;
        opencode-morph-fast-apply = import ../packages/opencode-morph-fast-apply.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        hunk = import ../packages/hunk {
          inherit pkgs;
          lib = pkgs.lib;
          bun2nix = inputs.bun2nix.packages.${system}.default;
        };
        openkanban = import ../packages/openkanban.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        sync-mcporter-instructions = pkgs.writeShellApplication {
          name = "sync-mcporter-instructions";
          runtimeInputs = [
            inputs.llm-agents.packages.${system}.mcporter
            pkgs.coreutils
            pkgs.diffutils
            pkgs.git
            pkgs.jq
          ];
          text = builtins.readFile ../scripts/sync-mcporter-instructions.sh;
        };
        download-llamacpp-models = pkgs.writeShellApplication {
          name = "download-llamacpp-models";
          runtimeInputs = [
            huggingfaceCli
            pkgs.coreutils
          ];
          text = ''
            set -euo pipefail

            if [ "$(id -u)" -ne 0 ]; then
              echo "error: run as root: sudo nix run .#download-llamacpp-models" >&2
              exit 1
            fi

            export HF_HOME=${lib.escapeShellArg hfHome}
            export HF_HUB_DOWNLOAD_TIMEOUT="''${HF_HUB_DOWNLOAD_TIMEOUT:-60}"

            install -d -m 0755 ${lib.escapeShellArg modelsDir}
            install -d -m 0700 ${lib.escapeShellArg hfHome}

            ${lib.concatStringsSep "\n\n" (lib.mapAttrsToList downloadModel modelFiles)}
          '';
        };
      }
      // {
        sentrux = import ../packages/sentrux.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
      }
      // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        helium = import ../packages/helium.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
        fincept-terminal = import ../packages/fincept-terminal.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
      };
  };
}
