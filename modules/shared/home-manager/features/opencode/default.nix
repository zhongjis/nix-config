{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./lsp.nix
    ./formatters.nix
    ./permission.nix
    ./provider.nix
    ./openagent.nix
  ];
  programs.opencode = {
    enable = true;
    # package = pkgs.writeShellScriptBin "opencode" ''
    #   export ANTHROPIC_API_KEY="$(cat ${config.sops.secrets.anthropic_api_key.path})"
    #   export OPENAI_API_KEY="$(cat ${config.sops.secrets.openrouter_api_key.path})"
    #   export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openai_api_key.path})"
    #   exec ${pkgs.opencode}/bin/opencode "$@"
    # '';
    enableMcpIntegration = true;

    settings = {
      autoshare = false;
      autoupdate = false;
    };
  };
}
