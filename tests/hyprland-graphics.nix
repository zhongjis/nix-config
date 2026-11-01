# Run: nix build --impure --no-link --file tests/hyprland-graphics.nix
let
  host = (builtins.getFlake (toString ../.)).nixosConfigurations.framework-16;
  inherit (host) config pkgs;
in
  pkgs.runCommand "hyprland-graphics-regression" {
    nativeBuildInputs = [pkgs.python3];
  }
  /* bash */
  ''
    python -c 'import ctypes; ctypes.CDLL("${config.hardware.graphics.package}/lib/gbm/dri_gbm.so")'
    echo 'PASS: system GBM backend loads with the host libc'
    touch "$out"
  ''
