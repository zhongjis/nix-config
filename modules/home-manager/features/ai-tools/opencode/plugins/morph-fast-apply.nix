# Morph Fast Apply Plugin Configuration
# https://github.com/JRedeker/opencode-morph-fast-apply
#
# Environment variable MORPH_API_KEY is provided via sops-nix
# Get your API key from: https://morphllm.com/dashboard/api-keys
#
# NOTE: OpenCode plugins read process.env at load time, not from OpenCode's
# {env:VAR} syntax. We use a shell alias to inject the secret before exec.
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
  opencodeBin = inputs.opencode.packages.${pkgs.system}.default;
in
  lib.mkIf (hasPlugin "opencode-morph-fast-apply") {
    sops.secrets.morph_api_key = {
      inherit sopsFile;
    };

    # Add morph instructions to opencode
    programs.opencode.settings.instructions = [
      "${morphPkg}/lib/node_modules/opencode-morph-fast-apply/MORPH_INSTRUCTIONS.md"
    ];

    # Shell alias that injects MORPH_API_KEY before launching opencode
    # This ensures the plugin receives the secret via process.env
    home.shellAliases.opencode = ''(export MORPH_API_KEY="$(<"${secretPath}")"; exec ${opencodeBin}/bin/opencode "$@")'';
  }
