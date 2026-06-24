{inputs, ...}: {
  perSystem = {
    config,
    pkgs,
    lib,
    system,
    ...
  }: {
    packages = let
      registry = import ../packages/registry.nix;
      argSources = {
        bun2nix = inputs.bun2nix.packages.${system}.default;
        agentBrowser = inputs.llm-agents.packages.${system}.agent-browser;
      };
      isAvailable = spec: !(spec.linuxOnly or false) || pkgs.stdenv.hostPlatform.isLinux;
      importCustomPackage = _name: spec:
        import spec.path ({
            inherit pkgs;
            lib = pkgs.lib;
          }
          // lib.genAttrs (spec.extraArgs or []) (argName: argSources.${argName}));
      customPackages =
        lib.mapAttrs importCustomPackage
        (lib.filterAttrs (_name: isAvailable) registry);
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

        oh-my-codex = inputs.llm-agents.packages.${system}.oh-my-codex;
        oh-my-opencode = import ../packages/oh-my-opencode.nix {
          inherit pkgs;
          lib = pkgs.lib;
          base = inputs.llm-agents.packages.${system}.oh-my-opencode;
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
      // customPackages;
  };
}
