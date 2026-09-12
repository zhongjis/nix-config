# Run from the repository root: nix build --impure --no-link --file tests/shadcn-mcp.nix
let
  inputs = (builtins.getFlake (toString ../.)).inputs;
  pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  serverFor = packages:
    (import ../modules/home-manager/features/ai-tools/common/mcp {
      pkgs = packages;
      inherit inputs;
      inherit (pkgs) lib;
      config = {};
      aiProfileHelpers = {
        isWork = false;
        isPersonal = false;
      };
    }).programs.mcp.servers.shadcn;
  server = serverFor pkgs;
  stub = pkgs.writeScriptBin "npx" ''
    #!${pkgs.python3}/bin/python3
    import json, os, sys
    print(json.dumps([os.environ["PATH"], sys.argv[1:]]))
    sys.exit(23)
  '';
  probe = serverFor (pkgs // {nodejs_24 = stub;});
in
  assert server.args == ["--yes" "shadcn@latest" "mcp"];
    pkgs.runCommand "shadcn-mcp-test" {
      nativeBuildInputs = [pkgs.python3 pkgs.shellcheck];
      passthru.wrapper = builtins.dirOf (builtins.dirOf server.command);
    } ''
      python3 - <<'PY'
      import json, os, subprocess

      command = ${builtins.toJSON probe.command}
      prefix = "${stub}/bin"
      args = ${builtins.toJSON server.args} + ["", "two words", "*", "--flag=value"]
      for inherited in (None, "", "/inherited/bin:/other/bin"):
          env = {} if inherited is None else {"PATH": inherited}
          result = subprocess.run([command, *args], env=env, text=True, capture_output=True)
          assert result.returncode == 23, (inherited, result)
          path, forwarded = json.loads(result.stdout)
          assert forwarded == args, forwarded
          assert path.split(":")[0] == prefix, path
          assert "" not in path.split(":"), path
          if inherited is not None:
              assert path == prefix + (":" + inherited if inherited else ""), path
          print(f"PATH={inherited!r}: prefix, forwarding, exit 23 OK")
      PY
      shellcheck ${server.command}
      ${pkgs.bash}/bin/bash -n ${server.command}
      touch "$out"
    ''
