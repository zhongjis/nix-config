# cmds
## build cmds
- install nix (https://zero-to-nix.com/start/install)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```
- switch MacOS
```bash
darwin-rebuild switch --flake .#mac-m1-max
```

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
- global
	- [ ] set global packages
	- [ ] consider migrate to flakeUtils?
- waybar
	- [ ] can always use some love. but not sure what to change. 
- zsh
	- [x] zsh syntax highlighting
- darwin
        - [ ] docker is not working directly downloaded from nixpkgs. seems relate to docker-daemon is not running. right now is using brew to manage it
- alacritty 
	- [x] term color is not working properly on macOS
	- [x] font too small on mac, too big on t480
	- [~] ~~toggle alacritty is not working properly 'skhd not found'~~
- neovim
	- [x] nightly is still not working
	- [x] auto format on nix file
	- [~] ~~use space instead of tabs in auto completion~~ (im happy with the default now)
	- [ ] markdown lsp
- tmux
	- [x] tmux clipboard with system clipboard
- github actions
	- [ ] add github actions to verify change works on both macos and nixos (at least compiles)
