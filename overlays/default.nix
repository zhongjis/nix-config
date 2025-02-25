# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: rec {
    # jdk = prev."jdk${toString 17}";
    # maven = prev.maven.override {inherit jdk;};
    xwayland = prev.xwayland.overrideAttrs (oldAttrs: {
      version = "24.1.4";
      src = prev.fetchurl {
        url = "mirror://xorg/individual/xserver/xwayland-24.1.4.tar.xz";
        hash = "sha256-2Wp426uBn1V1AXNERESZW1Ax69zBW3ev672NvAKvNPQ=";
      };
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
