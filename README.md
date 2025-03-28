# zshen's nix-config

This is my personal nix-config. It is always a work in progress as I love tweaking.

## Special Thanks

- https://github.com/vimjoyer/

## System Status

| host                  | home-manager profile              | system         |
| --------------------- | --------------------------------- | -------------- |
| framework-16          | zshen@framework-16                | x86_64-linux   |
| Zhongjies-MacBook-Pro | zshen@Zhongjies-MacBook-Pro.local | aarch64-darwin |
| vultr-lab             | zshen@vultr                       | x86_64-linux   |

| device        | host                    | OS      | system       |
| ------------- | ----------------------- | ------- | ------------ |
| thinkpad-t480 | homelab-0, homelab-1    | Proxmox | x86_64-linux |
| zimablade     | homelab-2, TrueNAS Core | Proxmox | x86_64-linux |

## Get Started

1. install nix (https://zero-to-nix.com/start/install)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

2. clone this repo
3. setup keys.txt (for sops-nix)

```nix
age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
```

### Nix-Darwin

```bash
# first time setup
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#mac-m1-max

# switch
nh darwin switch .
darwin-rebuild --list-generations
darwin-rebuild switch --switch-generation 41
```

### NixOS

- switch NixOS

```bash
nh os switch .
```

- test NixOS (TBD)

## Useful cmds

```bash
# useful nix cmds
nix run github:zhongjis/nix-update-input # upgrade specific input
nh search <query> # search nixpkgs
```

## Secret Management

I use [sops-nix](https://github.com/Mic92/sops-nix)'s home-manager module.

```bash
nix run nixpkgs#sops -- secrets.yaml # view secrets
```

more about sops see https://github.com/getsops/sops#2usage

# TODOs

NOTE: most of the changes (like for neovim) are changed on the way while im using it. this list just for later in case I have nothing to do.

see [here](https://github.com/users/zhongjis/projects/5)

## Notes

### Build directly from repo

adding inputs

```nix
inputs = {
    trouble-nvim = {
      url = "github:folke/trouble.nvim";
      flake = false;
    };
}
```

override in overlays

```nix
  modifications = final: prev: rec {
    vimPlugins =
      prev.vimPlugins
      // {
        trouble-nvim =
          prev.vimUtils.buildVimPlugin
          {
            name = "trouble.nvim";
            src = inputs.trouble-nvim;
          };
      };
  };
```
