# zshen's nix-config

This is my nix-config for my personal use. It is a work in progress and will be updated as I continue to use it.

## Special Thanks

- https://github.com/vimjoyer/

## System Status

| host          | profile     | system         |
| ------------- | ----------- | -------------- |
| thinkpad-t480 | zshen-linux | x86_64-linux   |
| razer-14      | zshen-razer | x86_64-linux   |
| mac-m1-max    | zshen-mac   | aarch64-darwin |

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
darwin-rebuild switch --flake .#mac-m1-max
darwin-rebuild --list-generations
darwin-rebuild switch --switch-generation 41
```

### NixOS

- switch NixOS (TBD)
- test NixOS (TBD)

## Useful cmds

```bash
# useful nix cmds
nix run github:vimjoyer/nix-update-input # upgrade specific input
nix search nixpkgs <package-name> # search nixpkgs

# rebuild system use nix-helper
oswitch # os switch
hswitch # home-manager switch
```

## Secret Management

I am using [sops-nix](https://github.com/Mic92/sops-nix)'s home-manager module.

```bash
nix run nixpkgs#sops -- secrets.yaml # view secrets
```

more about sops see https://github.com/getsops/sops#2usage
