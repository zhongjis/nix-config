# Run: nix build --no-link -f tests/antigravity-cli.nix
let
  inputs = (builtins.getFlake (toString ../.)).inputs;
  pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  merge = ../custom-home-manager-options/antigravity-cli/merge-settings.jq;
  managed = pkgs.writeText "managed.json" (builtins.toJSON {
    toolPermission = "always-proceed";
    permissions.deny = ["read_file(/a)" "read_file(/b)"];
  });
  live = pkgs.writeText "live.json" (builtins.toJSON {
    model = "runtime";
    toolPermission = "request-review";
    trustedWorkspaces = ["/w"];
    permissions = {
      allow = ["command(ls)"];
      deny = ["read_file(/a)"];
    };
  });
in
  pkgs.runCommand "antigravity-cli-merge-check" {nativeBuildInputs = [pkgs.jq];} ''
    jq -e --slurpfile managed ${managed} -f ${merge} ${live} > merged.json
    jq -e '
      .model == "runtime"
      and .trustedWorkspaces == ["/w"]
      and .toolPermission == "always-proceed"
      and .permissions.allow == ["command(ls)"]
      and .permissions.deny == ["read_file(/a)", "read_file(/b)"]
    ' merged.json
    echo '{}' | jq -e --slurpfile managed ${managed} -f ${merge} \
      | jq -e '.permissions.deny == ["read_file(/a)", "read_file(/b)"] and (has("model") | not)'
    touch $out
  ''
