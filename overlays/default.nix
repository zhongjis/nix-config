# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: rec {
    jdk = prev."jdk${toString 17}";
    maven = prev.maven.override {inherit jdk;};
    vimPlugins =
      prev.vimPlugins
      // {
        trouble-nvim =
          prev.vimUtils.buildVimPlugin
          {
            name = "trouble.nvim";
            src = inputs.trouble-v3;
          };
      };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
