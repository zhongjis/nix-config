{pkgs, ...}: let
in {
  programs.zed-editor = {
    enable = true;

    # Install Zed remote server for remote connections
    installRemoteServer = false;

    # Allow user to modify settings through Zed UI
    mutableUserSettings = true;
    mutableUserKeymaps = true;
    mutableUserTasks = true;
    mutableUserDebug = false;

    extraPackages = with pkgs; [
      nixd
      nil
    ];

    # Zed extensions for enhanced functionality
    extensions = [
      # Basic language support and syntax highlighting
      "nix"
      "python"
      "typescript"
      "javascript"
      "json"
      "yaml"
      "toml"
      "markdown"
      "dockerfile"
      "bash"
      "opencode"
    ];

    userSettings = {
      "agent_servers" = {
        "OpenCode" = {
          "command" = "opencode";
          "args" = ["acp"];
        };
      };
    };
  };
}
