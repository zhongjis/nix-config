# cmds

## build cmds

### install nix (https://zero-to-nix.com/start/install)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Global

```bash
oswitch
hswitch
```

### MacOS

- setup

```bash
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .#mac-m1-max
```

- switch

```bash
darwin-rebuild switch --flake .#mac-m1-max
darwin-rebuild --list-generations
darwin-rebuild switch --switch-generation 41
```

### NixOS

- switch NixOS

```bash

```

- test NixOS

```bash

```

## nix cmds

- upgrade specific package

```bash

```

- make nix lsp work

```bash
nix flake archive
```

- search nixpkgs

```bash
nix search nixpkgs <package-name>
```

# TODOs

NOTE: most of the changes (like for neovim) are changed on the way while im using it. this list just for later in case I have nothing to do.

## Global

- [ ] set global packages

### starship

- [ ] parent path not shown when in git worktree dir

### zsh

- [ ] bat syntax highlighting

### neovim

- [~] ~~use space instead of tabs in auto completion~~ (im happy with the default now)
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

## testing

### github actions

- [ ] add github actions to verify change works on both macos and nixos (at least compiles)
