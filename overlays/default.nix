# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  # hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  modifications = final: prev: rec {
    # jdk = prev."jdk${toString 17}";
    # maven = prev.maven.override {inherit jdk;};
    # xwayland = prev.xwayland.overrideAttrs (oldAttrs: {
    #   version = "24.1.4";
    #   src = prev.fetchurl {
    #     url = "mirror://xorg/individual/xserver/xwayland-24.1.4.tar.xz";
    #     hash = "sha256-2Wp426uBn1V1AXNERESZW1Ax69zBW3ev672NvAKvNPQ=";
    #   };
    # });
    kubelogin = prev.kubelogin.overrideAttrs (oldAttrs: rec {
      version = "0.1.9";

      src = prev.fetchFromGitHub {
        owner = "Azure";
        repo = "kubelogin";
        rev = "v${version}";
        sha256 = "sha256-u9Fj2YkHVbFHpxrrxdYrRBvbGsLvxQQlsPHf4++L0g0=";
      };

      vendorHash = "sha256-HYUI0x4fCA8nhIHPguGCJ+F36fxb7m97bgyigwiXWd8=";
    });
    gamescope = prev.gamescope.overrideAttrs (oldAttrs: rec {
      version = "3.15.13";
      src = prev.fetchFromGitHub {
        owner = "ValveSoftware";
        repo = "gamescope";
        rev = "refs/tags/${version}";
        fetchSubmodules = true;
        hash = "sha256-AePYKdDyAtnVkL8/VeWmhJ3ATZnhyVZcU/QtVpCfTQE=";
      };

      patches = [
        ./gamescope/shaders-path.patch
        ./gamescope/gamescopereaper.patch
      ];
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
