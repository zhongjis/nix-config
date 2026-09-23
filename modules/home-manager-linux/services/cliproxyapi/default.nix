{
  config,
  inputs,
  lib,
  pkgs,
  currentSystemName,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cliProxyApi = inputs.llm-agents.packages.${system}.cli-proxy-api;
  usageKeeper = inputs.llm-agents.packages.${system}.cpa-usage-keeper;
  keeperStateDir = "${config.xdg.stateHome}/cpa-usage-keeper";
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  stateDir = "${config.xdg.stateHome}/cliproxyapi";
  authDir = "${stateDir}/auth";
  apiKeyFile = "${stateDir}/api-key";
  configFile = "${stateDir}/config.yaml";
  managementKeyFile = config.sops.secrets.cliproxyapi_management_key.path;
  yamlQuote = value: "'${lib.replaceStrings ["'"] ["''"] value}'";
  initialize = pkgs.writeShellScript "cliproxyapi-initialize" ''
    stateDir=${lib.escapeShellArg stateDir}
    authDir=${lib.escapeShellArg authDir}
    apiKeyFile=${lib.escapeShellArg apiKeyFile}
    configFile=${lib.escapeShellArg configFile}
    managementKeyFile=${lib.escapeShellArg managementKeyFile}

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

    ${pkgs.coreutils}/bin/test -s "$managementKeyFile"
    managementKeyYaml="$(${pkgs.python3}/bin/python3 -c 'import json, sys; json.dump(sys.stdin.read(), sys.stdout)' < "$managementKeyFile")"
    apiKey="$(${pkgs.coreutils}/bin/cat "$apiKeyFile")"
    umask 077
    configTmp="$(${pkgs.coreutils}/bin/mktemp "$stateDir/.config.yaml.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$configTmp"' EXIT
    ${pkgs.coreutils}/bin/printf '%s\n' \
      'host: 127.0.0.1' \
      'port: 8317' \
      'usage-statistics-enabled: true' \
      ${lib.escapeShellArg "auth-dir: ${yamlQuote authDir}"} \
      'api-keys:' \
      "  - $apiKey" \
      'remote-management:' \
      '  allow-remote: false' \
      "  secret-key: $managementKeyYaml" \
      'routing:' \
      '  strategy: round-robin' > "$configTmp"
    ${pkgs.coreutils}/bin/chmod 600 "$configTmp"
    ${pkgs.coreutils}/bin/mv -f "$configTmp" "$configFile"
    trap - EXIT
  '';
  startKeeper = pkgs.writeShellScript "cpa-usage-keeper-start" ''
    set -euo pipefail
    umask 077
    stateDir=${lib.escapeShellArg keeperStateDir}
    passwordFile="$stateDir/login-password"
    managementKeyFile=${lib.escapeShellArg managementKeyFile}

    test -f "$managementKeyFile" && test -s "$managementKeyFile"
    CPA_MANAGEMENT_KEY="$(< "$managementKeyFile")"
    test -n "$CPA_MANAGEMENT_KEY"

    ${pkgs.coreutils}/bin/install -d -m 700 "$stateDir"
    test ! -L "$passwordFile"
    if [ ! -e "$passwordFile" ]; then
      password="$(${pkgs.coreutils}/bin/od -An -N32 -tx1 /dev/urandom | ${pkgs.coreutils}/bin/tr -d ' \n')"
      (set -C; printf '%s\n' "$password" > "$passwordFile")
      unset password
    fi
    test -f "$passwordFile" && test -s "$passwordFile"
    ${pkgs.coreutils}/bin/chmod 600 "$passwordFile"
    LOGIN_PASSWORD="$(< "$passwordFile")"
    test -n "$LOGIN_PASSWORD"
    export CPA_MANAGEMENT_KEY LOGIN_PASSWORD
    exec ${lib.getExe usageKeeper}
  '';
in {
  assertions = [
    {
      assertion = currentSystemName == "framework-16" && config.myHomeManager.aiProfile == "personal";
      message = "CLIProxyAPI and CPA Usage Keeper may only be enabled on framework-16 with the personal profile";
    }
  ];

  sops.secrets.cliproxyapi_management_key = {
    inherit sopsFile;
  };

  home.packages = [
    cliProxyApi
    (pkgs.writeShellScriptBin "cliproxyapi-login" ''
      umask 077
      ${initialize}
      exec ${lib.getExe cliProxyApi} --config ${lib.escapeShellArg configFile} --codex-login "$@"
    '')
  ];

  systemd.user.services.cliproxyapi = {
    Unit = {
      Description = "CLIProxyAPI";
      After = ["sops-nix.service"];
      Requires = ["sops-nix.service"];
    };
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

  systemd.user.services.cpa-usage-keeper = {
    Unit = {
      Description = "CPA Usage Keeper";
      After = ["cliproxyapi.service" "sops-nix.service"];
      Requires = ["cliproxyapi.service" "sops-nix.service"];
    };
    Service = {
      ExecStart = "${startKeeper}";
      Environment = [
        "APP_HOST=127.0.0.1"
        "APP_PORT=19487"
        "CPA_BASE_URL=http://127.0.0.1:8317"
        "AUTH_ENABLED=true"
        "WORK_DIR=${keeperStateDir}"
      ];
      Restart = "on-failure";
      RestartSec = "5s";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      StateDirectory = "cpa-usage-keeper";
      StateDirectoryMode = "0700";
      ReadWritePaths = [keeperStateDir];
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
      RestrictSUIDSGID = true;
      LockPersonality = true;
    };
    Install.WantedBy = ["default.target"];
  };
}
