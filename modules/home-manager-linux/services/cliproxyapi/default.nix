{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cliProxyApi = inputs.llm-agents.packages.${system}.cli-proxy-api;
  stateDir = "${config.xdg.stateHome}/cliproxyapi";
  authDir = "${stateDir}/auth";
  apiKeyFile = "${stateDir}/api-key";
  configFile = "${stateDir}/config.yaml";
  yamlQuote = value: "'${lib.replaceStrings ["'"] ["''"] value}'";
  initialize = pkgs.writeShellScript "cliproxyapi-initialize" ''
    stateDir=${lib.escapeShellArg stateDir}
    authDir=${lib.escapeShellArg authDir}
    apiKeyFile=${lib.escapeShellArg apiKeyFile}
    configFile=${lib.escapeShellArg configFile}

    ${pkgs.coreutils}/bin/install -d -m 700 "$stateDir" "$authDir"

    if [ ! -s "$apiKeyFile" ]; then
      apiKey="$(${pkgs.coreutils}/bin/od -An -N32 -tx1 /dev/urandom | ${pkgs.coreutils}/bin/tr -d ' \n')"
      (
        umask 077
        set -C
        ${pkgs.coreutils}/bin/printf '%s\n' "$apiKey" > "$apiKeyFile"
      ) 2>/dev/null || true
    fi
    ${pkgs.coreutils}/bin/test -s "$apiKeyFile"
    ${pkgs.coreutils}/bin/chmod 600 "$apiKeyFile"

    apiKey="$(${pkgs.coreutils}/bin/cat "$apiKeyFile")"
    umask 077
    configTmp="$(${pkgs.coreutils}/bin/mktemp "$stateDir/.config.yaml.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$configTmp"' EXIT
    ${pkgs.coreutils}/bin/printf '%s\n' \
      'host: 127.0.0.1' \
      'port: 8317' \
      ${lib.escapeShellArg "auth-dir: ${yamlQuote authDir}"} \
      'api-keys:' \
      "  - $apiKey" \
      'routing:' \
      '  strategy: round-robin' > "$configTmp"
    ${pkgs.coreutils}/bin/chmod 600 "$configTmp"
    ${pkgs.coreutils}/bin/mv -f "$configTmp" "$configFile"
    trap - EXIT
  '';
in {
  home.packages = [
    cliProxyApi
    (pkgs.writeShellScriptBin "cliproxyapi-login" ''
      umask 077
      ${initialize}
      exec ${lib.getExe cliProxyApi} --config ${lib.escapeShellArg configFile} --codex-login "$@"
    '')
  ];

  systemd.user.services.cliproxyapi = {
    Unit.Description = "CLIProxyAPI";
    Service = {
      ExecStartPre = "${initialize}";
      ExecStart = "${lib.getExe cliProxyApi} --config ${lib.escapeShellArg configFile}";
      Restart = "on-failure";
      RestartSec = "5s";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      StateDirectory = "cliproxyapi";
      StateDirectoryMode = "0700";
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
      RestrictSUIDSGID = true;
      LockPersonality = true;
    };
    Install.WantedBy = ["default.target"];
  };
}
