# zshen's nix-config

## install nix (https://zero-to-nix.com/start/install)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Global

```bash
oswitch # os switch
hswitch # home-manager switch
```

## MacOS-only

```bash
# first time setup
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#mac-m1-max

# switch
darwin-rebuild switch --flake .#mac-m1-max
darwin-rebuild --list-generations
darwin-rebuild switch --switch-generation 41
```

## NixOS-only

- switch NixOS (TBD)
- test NixOS (TBD)

## useful nix cmds

```bash
nix run github:vimjoyer/nix-update-input # upgrade specific input
nix search nixpkgs <package-name> # search nixpkgs
```

## secret management

I am using [sops-nix](https://github.com/Mic92/sops-nix)'s home-manager module.

```nix
age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
```

```bash
nix run nixpkgs#sops -- secrets.yaml # view secrets
```

more about sops see https://github.com/getsops/sops#2usage

# TODOs

NOTE: most of the changes (like for neovim) are changed on the way while im using it. this list just for later in case I have nothing to do.

### Global

- [ ] set global packages

### starship

- [ ] parent path not shown when in git worktree dir

### bat

- [ ] syntax highlighting error when apply home-manager config
- [ ] make it simple with just syntax highlighting

### zsh

- [ ] bat syntax highlighting

### neovim

- [ ] markdown lint
- [ ] verify luasnippet is working correctly

## nixos

### waybar

- [ ] copy sketchybar style to waybar

### gaming

- [ ] create/copy a nvidia module setup

## nix-darwin

- [ ] docker is not working directly downloaded from nixpkgs. seems relate to docker-daemon is not running. right now is using brew to manage it
- [ ] aerospace and sketchybar integration not working

```

```
