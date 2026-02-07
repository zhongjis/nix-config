# Morph Fast Apply Plugin Configuration
# https://github.com/JRedeker/opencode-morph-fast-apply
#
# Environment variable MORPH_API_KEY is provided via sops-nix
# Get your API key from: https://morphllm.com/dashboard/api-keys
{
  config,
  lib,
  pkgs,
  hasPlugin,
  inputs,
  ...
}: let
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  morphPkg = inputs.self.packages.${pkgs.system}.opencode-morph-fast-apply;
  secretPath = config.sops.secrets.morph_api_key.path;
in
  lib.mkIf (hasPlugin "opencode-morph-fast-apply") {
    sops.secrets.morph_api_key = {
      inherit sopsFile;
    };

    # Add morph instructions to opencode
    programs.opencode.settings.instructions = [
      "${morphPkg}/lib/node_modules/opencode-morph-fast-apply/MORPH_INSTRUCTIONS.md"
    ];

    # Export MORPH_API_KEY directly in zsh initialization
    # Reads the sops secret file at shell startup
    programs.zsh.initContent = lib.mkOrder 100 ''
      if [[ -r "${secretPath}" ]]; then
        export MORPH_API_KEY="$(<"${secretPath}")"
      fi
    '';
  }
