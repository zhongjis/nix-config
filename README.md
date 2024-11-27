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
<<<<<<< Updated upstream

# TODOs

NOTE: most of the changes (like for neovim) are changed on the way while im using it. this list just for later in case I have nothing to do.

### Global

- [x] set global packages

### starship

- [ ] parent path not shown when in git worktree dir

### bat

- [x] syntax highlighting error when apply home-manager config
- [ ] make it simple with just syntax highlighting

### zsh

- [ ] bat syntax highlighting

### neovim

- [-] markdown lint
- [ ] verify luasnippet is working correctly

## nixos

### waybar

- [-] copy sketchybar style to waybar

### gaming

- [x] create/copy a nvidia module setup

## nix-darwin

- [x] docker is not working directly downloaded from nixpkgs. seems relate to docker-daemon is not running. right now is using brew to manage it
- [-] aerospace and sketchybar integration not working

## stylix

=======

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
