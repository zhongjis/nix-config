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
